;; Violation Detection Contract
;; Identifies and records noise violations

(define-map violations
  { violation-id: uint }
  {
    sensor-id: uint,
    zone-id: uint,
    decibel-level: uint,
    threshold-exceeded: uint,
    timestamp: uint,
    severity: (string-ascii 10),
    status: (string-ascii 20),
    reported-by: principal
  }
)

(define-map violation-counts
  { zone-id: uint, date: uint }
  { count: uint }
)

(define-data-var next-violation-id uint u1)

;; Error constants
(define-constant ERR-NO-VIOLATION (err u400))
(define-constant ERR-VIOLATION-NOT-FOUND (err u401))

;; Report a noise violation
(define-public (report-violation (sensor-id uint) (zone-id uint) (decibel-level uint) (threshold uint) (hour uint))
  (let (
    (violation-id (var-get next-violation-id))
    (timestamp (unwrap-panic (get-block-info? time (- block-height u1))))
    (severity (calculate-severity decibel-level threshold))
  )
    ;; Check if it's actually a violation
    (asserts! (> decibel-level threshold) ERR-NO-VIOLATION)

    (map-set violations
      { violation-id: violation-id }
      {
        sensor-id: sensor-id,
        zone-id: zone-id,
        decibel-level: decibel-level,
        threshold-exceeded: (- decibel-level threshold),
        timestamp: timestamp,
        severity: severity,
        status: "open",
        reported-by: tx-sender
      }
    )

    ;; Update violation count for the day
    (update-violation-count zone-id timestamp)

    (var-set next-violation-id (+ violation-id u1))
    (ok violation-id)
  )
)

;; Calculate violation severity
(define-private (calculate-severity (decibel-level uint) (threshold uint))
  (let ((excess (- decibel-level threshold)))
    (if (<= excess u5)
      "low"
      (if (<= excess u15)
        "medium"
        "high"
      )
    )
  )
)

;; Update violation count for a zone on a given day
(define-private (update-violation-count (zone-id uint) (timestamp uint))
  (let ((date (/ timestamp u86400)))
    (match (map-get? violation-counts { zone-id: zone-id, date: date })
      existing-count
      (map-set violation-counts
        { zone-id: zone-id, date: date }
        { count: (+ (get count existing-count) u1) }
      )
      (map-set violation-counts
        { zone-id: zone-id, date: date }
        { count: u1 }
      )
    )
  )
)

;; Resolve a violation
(define-public (resolve-violation (violation-id uint))
  (match (map-get? violations { violation-id: violation-id })
    violation-data
    (begin
      (map-set violations
        { violation-id: violation-id }
        (merge violation-data { status: "resolved" })
      )
      (ok true)
    )
    ERR-VIOLATION-NOT-FOUND
  )
)

;; Get violation details
(define-read-only (get-violation (violation-id uint))
  (map-get? violations { violation-id: violation-id })
)

;; Get violation count for a zone on a specific date
(define-read-only (get-violation-count (zone-id uint) (date uint))
  (default-to { count: u0 } (map-get? violation-counts { zone-id: zone-id, date: date }))
)
