;; Sensor Verification Contract
;; Validates and manages noise monitoring devices

(define-map sensors
  { sensor-id: uint }
  {
    owner: principal,
    location: (string-ascii 100),
    verified: bool,
    registration-block: uint
  }
)

(define-map sensor-counter uint uint)

(define-data-var next-sensor-id uint u1)

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SENSOR-NOT-FOUND (err u101))
(define-constant ERR-SENSOR-ALREADY-EXISTS (err u102))

;; Register a new sensor
(define-public (register-sensor (location (string-ascii 100)))
  (let ((sensor-id (var-get next-sensor-id)))
    (map-set sensors
      { sensor-id: sensor-id }
      {
        owner: tx-sender,
        location: location,
        verified: false,
        registration-block: block-height
      }
    )
    (var-set next-sensor-id (+ sensor-id u1))
    (ok sensor-id)
  )
)

;; Verify a sensor (admin function)
(define-public (verify-sensor (sensor-id uint))
  (match (map-get? sensors { sensor-id: sensor-id })
    sensor-data
    (begin
      (map-set sensors
        { sensor-id: sensor-id }
        (merge sensor-data { verified: true })
      )
      (ok true)
    )
    ERR-SENSOR-NOT-FOUND
  )
)

;; Get sensor info
(define-read-only (get-sensor (sensor-id uint))
  (map-get? sensors { sensor-id: sensor-id })
)

;; Check if sensor is verified
(define-read-only (is-sensor-verified (sensor-id uint))
  (match (map-get? sensors { sensor-id: sensor-id })
    sensor-data (get verified sensor-data)
    false
  )
)
