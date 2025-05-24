;; Threshold Management Contract
;; Establishes and manages noise standards for different zones

(define-map zone-thresholds
  { zone-id: uint }
  {
    zone-name: (string-ascii 50),
    day-threshold: uint,
    night-threshold: uint,
    zone-type: (string-ascii 20),
    created-by: principal
  }
)

(define-map time-periods
  uint
  {
    start-hour: uint,
    end-hour: uint,
    period-type: (string-ascii 10)
  }
)

(define-data-var next-zone-id uint u1)

;; Error constants
(define-constant ERR-ZONE-NOT-FOUND (err u300))
(define-constant ERR-INVALID-THRESHOLD (err u301))
(define-constant ERR-INVALID-TIME (err u302))

;; Initialize default time periods
(map-set time-periods u1 { start-hour: u6, end-hour: u22, period-type: "day" })
(map-set time-periods u2 { start-hour: u22, end-hour: u6, period-type: "night" })

;; Create a new zone with thresholds
(define-public (create-zone (zone-name (string-ascii 50)) (zone-type (string-ascii 20)) (day-threshold uint) (night-threshold uint))
  (let ((zone-id (var-get next-zone-id)))
    ;; Validate thresholds
    (asserts! (and (> day-threshold u0) (> night-threshold u0) (<= day-threshold u150) (<= night-threshold u150)) ERR-INVALID-THRESHOLD)

    (map-set zone-thresholds
      { zone-id: zone-id }
      {
        zone-name: zone-name,
        day-threshold: day-threshold,
        night-threshold: night-threshold,
        zone-type: zone-type,
        created-by: tx-sender
      }
    )
    (var-set next-zone-id (+ zone-id u1))
    (ok zone-id)
  )
)

;; Update zone thresholds
(define-public (update-thresholds (zone-id uint) (day-threshold uint) (night-threshold uint))
  (match (map-get? zone-thresholds { zone-id: zone-id })
    zone-data
    (begin
      (asserts! (and (> day-threshold u0) (> night-threshold u0) (<= day-threshold u150) (<= night-threshold u150)) ERR-INVALID-THRESHOLD)
      (map-set zone-thresholds
        { zone-id: zone-id }
        (merge zone-data { day-threshold: day-threshold, night-threshold: night-threshold })
      )
      (ok true)
    )
    ERR-ZONE-NOT-FOUND
  )
)

;; Get zone thresholds
(define-read-only (get-zone (zone-id uint))
  (map-get? zone-thresholds { zone-id: zone-id })
)

;; Get current threshold based on time
(define-read-only (get-current-threshold (zone-id uint) (hour uint))
  (match (map-get? zone-thresholds { zone-id: zone-id })
    zone-data
    (if (and (>= hour u6) (< hour u22))
      (some (get day-threshold zone-data))
      (some (get night-threshold zone-data))
    )
    none
  )
)

;; Check if noise level exceeds threshold
(define-read-only (exceeds-threshold (zone-id uint) (decibel-level uint) (hour uint))
  (match (get-current-threshold zone-id hour)
    threshold (> decibel-level threshold)
    false
  )
)
