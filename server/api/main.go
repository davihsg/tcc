package main

import (
	"database/sql"
	"os"

	_ "github.com/mattn/go-sqlite3"

	"github.com/gin-gonic/gin"
)

var db *sql.DB

func main() {
	dbPath := os.Getenv("DB_PATH")
	if dbPath == "" {
		dbPath = "items.db"
	}

	var err error

	db, err = sql.Open("sqlite3", dbPath)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	router := gin.Default()

	WithoutAuthHandler(router)

	WithAuthHandler(router)

	router.Run(":80")
}
