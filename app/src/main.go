package main

import (
	"flag"
	"fmt"
	"net/http"
	"os"
)

var greeting string

func main() {
	flag.StringVar(&greeting, "greeting", "hello", "message the app will display")
	flag.Parse()

	port, found := os.LookupEnv("PORT")
	if !found {
		port = "8080"
	}

	mux := http.NewServeMux()
	mux.HandleFunc("/", indexHandler)
	mux.HandleFunc("/health", healthHandler)

	fmt.Printf("Listening on http://localhost:%s\n", port)
	http.ListenAndServe(fmt.Sprintf(":%s", port), mux)
}

func indexHandler(w http.ResponseWriter, r *http.Request) {
	// comment line below to make tests fail
	// http.Error(w, "", http.StatusServiceUnavailable)
	fmt.Fprintf(w, greeting)
	return
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.Write([]byte("{\"status\": \"healthy\"}"))
	return
}
