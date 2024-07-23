package main

import (
	"database/sql"

	_ "github.com/mattn/go-sqlite3"

	"github.com/gin-gonic/gin"
)

var db *sql.DB

func main() {
	var err error
	db, err = sql.Open("sqlite3", "./items.db")
	if err != nil {
		panic(err)
	}
	defer db.Close()

	router := gin.Default()

	WithoutAuthHandler(router)

	WithAuthHandler(router)

	router.Run(":80")
}
