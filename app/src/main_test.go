package main

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestIndexHandler(t *testing.T) {
	// create request
	req, err := http.NewRequest("GET", "/", nil)
	if err != nil {
		t.Fatal(err)
	}

	// create a response recorder for the handler
	rr := httptest.NewRecorder()
	handler := http.HandlerFunc(indexHandler)

	// call the handler
	handler.ServeHTTP(rr, req)

	// check the response is what we expect
	if status := rr.Code; status != http.StatusOK {
		t.Errorf("handler returned wrong status code: got %v expected %v",
			status, http.StatusOK)
	}
}
