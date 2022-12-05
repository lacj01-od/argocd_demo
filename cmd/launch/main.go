package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	value, present := os.LookupEnv("TEST_MESSAGE")
	if !present {
		value = "No Value"
	}
	web := &http.ServeMux{}
	health := &http.ServeMux{}

	web.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Saying Hello with %s ", value)
	})
	health.HandleFunc("/health", func(writer http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(writer, `{ "status" : "200" }`)
	})

	go func() {
		err := http.ListenAndServe(":8081", web)
		if err != nil {
			log.Fatal(err)
		}
	}()

	err := http.ListenAndServe(":8080", health)
	if err != nil {
		log.Fatal(err)
	}
}
