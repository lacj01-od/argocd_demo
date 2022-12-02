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
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Saying Hello with %s ", value)
	})

	log.Fatal(http.ListenAndServe(":8081", nil))
}
