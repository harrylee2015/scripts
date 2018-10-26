package go_utils

import (
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"os/exec"
	"path"
	"strings"
	"sync"
	"time"

	"github.com/pkg/sftp"
	"golang.org/x/crypto/ssh"
)

type ScpInfo struct {
	UserName      string
	PassWord      string
	HostIp        string
	Port          int
	LocalFilePath string
	RemoteDir     string
}

type CmdInfo struct {
	userName  string
	passWord  string
	hostIp    string
	port      int
	cmd       string
	remoteDir string
}

func sshconnect(user, password, host string, port int) (*ssh.Session, error) {
	var (
		auth         []ssh.AuthMethod
		addr         string
		clientConfig *ssh.ClientConfig
		client       *ssh.Client
		session      *ssh.Session
		err          error
	)
	// get auth method
	auth = make([]ssh.AuthMethod, 0)
	auth = append(auth, ssh.Password(password))

	clientConfig = &ssh.ClientConfig{
		User:    user,
		Auth:    auth,
		Timeout: 30 * time.Second,
		//需要验证服务端，不做验证返回nil就可以
		HostKeyCallback: func(hostname string, remote net.Addr, key ssh.PublicKey) error {
			return nil
		},
	}
	// connet to ssh
	addr = fmt.Sprintf("%s:%d", host, port)
	if client, err = ssh.Dial("tcp", addr, clientConfig); err != nil {
		return nil, err
	}
	// create session
	if session, err = client.NewSession(); err != nil {
		return nil, err
	}
	return session, nil
}

func sftpconnect(user, password, host string, port int) (*sftp.Client, error) {
	var (
		auth         []ssh.AuthMethod
		addr         string
		clientConfig *ssh.ClientConfig
		sshClient    *ssh.Client
		sftpClient   *sftp.Client
		err          error
	)
	// get auth method
	auth = make([]ssh.AuthMethod, 0)
	auth = append(auth, ssh.Password(password))

	clientConfig = &ssh.ClientConfig{
		User:    user,
		Auth:    auth,
		Timeout: 30 * time.Second,
		//需要验证服务端，不做验证返回nil就可以
		HostKeyCallback: func(hostname string, remote net.Addr, key ssh.PublicKey) error {
			return nil
		},
	}
	// connet to ssh
	addr = fmt.Sprintf("%s:%d", host, port)

	if sshClient, err = ssh.Dial("tcp", addr, clientConfig); err != nil {
		return nil, err
	}
	// create sftp client
	if sftpClient, err = sftp.NewClient(sshClient); err != nil {
		return nil, err
	}
	return sftpClient, nil
}

func ScpFileFromLocalToRemote(si *ScpInfo) {
	sftpClient, err := sftpconnect(si.UserName, si.PassWord, si.HostIp, si.Port)
	if err != nil {
		fmt.Println("sftconnect have a err!")
		log.Fatal(err)
		panic(err)
	}
	defer sftpClient.Close()
	srcFile, err := os.Open(si.LocalFilePath)
	if err != nil {
		log.Fatal(err)
		panic(err)
	}
	defer srcFile.Close()

	var remoteFileName = path.Base(si.LocalFilePath)
	fmt.Println("remoteFileName:", remoteFileName)
	dstFile, err := sftpClient.Create(path.Join(si.RemoteDir, remoteFileName))
	if err != nil {
		log.Fatal(err)
	}
	defer dstFile.Close()
	//bufReader := bufio.NewReader(srcFile)
	//b := bytes.NewBuffer(make([]byte,0))

	buf := make([]byte, 1024000)
	for {
		//n, err := bufReader.Read(buf)
		n, _ := srcFile.Read(buf)
		if err != nil && err != io.EOF {
			panic(err)
		}
		if n == 0 {
			break
		}
		dstFile.Write(buf[0:n])
	}
	fmt.Println("copy file to remote server finished!")
}

func RemoteExec(cmdInfo *CmdInfo) error {
	//A Session only accepts one call to Run, Start or Shell.
	session, err := sshconnect(cmdInfo.userName, cmdInfo.passWord, cmdInfo.hostIp, cmdInfo.port)
	if err != nil {
		return err
	}
	defer session.Close()
	session.Stdout = os.Stdout
	session.Stderr = os.Stderr
	err = session.Run(cmdInfo.cmd)
	return err
}

func remoteScp(si *ScpInfo, reqnum chan struct{}) {
	defer func() {
		reqnum <- struct{}{}
	}()
	ScpFileFromLocalToRemote(si)
	//session, err := sshconnect("ubuntu", "Fuzamei#123456", "raft15258.chinacloudapp.cn", 22)
	fmt.Println("remoteScp file sucessfully!:")

}
func Exec_cmd(cmd string, wg *sync.WaitGroup) {
	fmt.Println(cmd)
	parts := strings.Fields(cmd)
	out, err := exec.Command(parts[0], parts[1]).Output()
	if err != nil {
		fmt.Println("error occured")
		fmt.Printf("%s", err)
	}
	fmt.Printf("%s", out)
	wg.Done()
}
func Exec_shell(s string) error {
	cmd := exec.Command("/bin/bash", "-c", s)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	err := cmd.Run()
	if err != nil {
		return err
	}
	return nil
}
