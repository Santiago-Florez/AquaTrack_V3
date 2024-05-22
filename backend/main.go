package main

import (
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"sync"

	_ "github.com/lib/pq"
)

type Activity struct {
	ActivityID           int     `json:"activity_id"`
	CantidadLitrosTiempo float64 `json:"cantidad_litros_tiempo"`
	NombreActividad      string  `json:"nombre_actividad"`
}

type MedidorAgua struct {
	PersonaID        int     `json:"persona_id"`
	ActividadID      int     `json:"actividad_id"`
	TiempoActividad  float64 `json:"tiempo_actividad"`
	AproxAguaGastada float64 `json:"aprox_agua_gastada"`
}

var (
	db  *sql.DB
	mu  sync.Mutex
	err error
)

func main() {
	connStr := "user=postgres password=admin123 dbname=aquatrack sslmode=disable"
	db, err = sql.Open("postgres", connStr)
	if err != nil {
		log.Fatal(err)
	}

	defer db.Close()

	http.HandleFunc("/register", registerHandler)
	http.HandleFunc("/history", historyHandler)
	http.HandleFunc("/activities", activitiesHandler)

	log.Println("Server is running on port 8080")
	if err := http.ListenAndServe(":8080", enableCors(http.DefaultServeMux)); err != nil {
		log.Fatal("Error starting server:", err)
	}
}

func registerHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == http.MethodPost {
		var medidor MedidorAgua
		if err := json.NewDecoder(r.Body).Decode(&medidor); err != nil {
			log.Println("Error decoding JSON:", err)
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		var cantidadLitrosTiempo float64
		err = db.QueryRow("SELECT cantidad_litros_tiempo FROM actividad WHERE actividad_id = $1", medidor.ActividadID).Scan(&cantidadLitrosTiempo)
		if err != nil {
			log.Println("Error querying actividad:", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		medidor.AproxAguaGastada = medidor.TiempoActividad * cantidadLitrosTiempo

		_, err = db.Exec("INSERT INTO medidoragua (persona_id, actividad_id, tiempo_actividad, aprox_agua_gastada) VALUES ($1, $2, $3, $4)",
			medidor.PersonaID, medidor.ActividadID, medidor.TiempoActividad, medidor.AproxAguaGastada)
		if err != nil {
			log.Println("Error inserting into medidoragua:", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusOK)
	} else {
		log.Println("Invalid request method")
		http.Error(w, "Invalid request method", http.StatusMethodNotAllowed)
	}
}

func historyHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT persona_id, actividad_id, tiempo_actividad, aprox_agua_gastada FROM medidoragua ORDER BY medidor_id DESC")
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var medidores []MedidorAgua
	for rows.Next() {
		var medidor MedidorAgua
		if err := rows.Scan(&medidor.PersonaID, &medidor.ActividadID, &medidor.TiempoActividad, &medidor.AproxAguaGastada); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		medidores = append(medidores, medidor)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(medidores)
}

func activitiesHandler(w http.ResponseWriter, r *http.Request) {
	rows, err := db.Query("SELECT actividad_id, nombreactividad FROM actividad")
	if err != nil {
		log.Println("Error querying activities:", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	defer rows.Close()

	var activities []Activity
	for rows.Next() {
		var activity Activity
		if err := rows.Scan(&activity.ActivityID, &activity.NombreActividad); err != nil {
			log.Println("Error scanning activity:", err)
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		activities = append(activities, activity)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(activities)
}

func enableCors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		next.ServeHTTP(w, r)
	})
}
