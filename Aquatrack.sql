CREATE TABLE Persona (
    Cedula SERIAL PRIMARY KEY,
    Nombre VARCHAR(255),
    Apellido VARCHAR(255)
);

CREATE TABLE Actividad (
    Actividad_ID SERIAL PRIMARY KEY,
    NombreActividad VARCHAR(255),
    Cantidad_litros_tiempo FLOAT
);

CREATE TABLE MedidorAgua (
    Medidor_ID SERIAL PRIMARY KEY,
    Persona_ID INTEGER REFERENCES Persona(Cedula),
    Actividad_ID INTEGER REFERENCES Actividad(Actividad_ID),
    Tiempo_actividad FLOAT,
    aprox_agua_gastada FLOAT
);

ALTER TABLE Actividad ADD COLUMN NombreActividad VARCHAR(255);

INSERT INTO Actividad (Cantidad_litros_tiempo, NombreActividad) VALUES (1.5, 'Lavar los trastes');
INSERT INTO Actividad (Cantidad_litros_tiempo, NombreActividad) VALUES (2.0, 'Ducharse');
INSERT INTO Actividad (Cantidad_litros_tiempo, NombreActividad) VALUES (1.0, 'Lavar ropa');

