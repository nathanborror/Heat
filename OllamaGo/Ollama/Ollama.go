package Ollama

import (
	"io"
	"net"
	"net/http"

	"github.com/jmorganca/ollama/server"
)

// Get makes an HTTP(S) GET request to url,
// returning the resulting content or an error.
func Get(url string) ([]byte, error) {
	res, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer res.Body.Close()
	return io.ReadAll(res.Body)
}

// Version returns the version string for this package.
func Version() string {
	return "0.0.1"
}

func RunServer() {
	host, port := "127.0.0.1", "8080"

	ln, _ := net.Listen("tcp", net.JoinHostPort(host, port))

	var origins []string
	server.Serve(ln, origins)
}
