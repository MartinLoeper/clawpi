package web

import (
	"embed"
	"io/fs"
	"log"
	"net"
	"net/http"
)

//go:embed landing-page
var landingFS embed.FS

func Serve(addr string) error {
	sub, err := fs.Sub(landingFS, "landing-page")
	if err != nil {
		return err
	}

	mux := http.NewServeMux()
	mux.Handle("/", http.FileServer(http.FS(sub)))

	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return err
	}
	log.Printf("web server listening on %s", addr)
	return http.Serve(ln, mux)
}
