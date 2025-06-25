;; Contract Analyst Verification System
;; Validates and manages contract performance analysts

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ANALYST_EXISTS (err u101))
(define-constant ERR_ANALYST_NOT_FOUND (err u102))
(define-constant ERR_INVALID_CREDENTIALS (err u103))

;; Data Variables
(define-data-var next-analyst-id uint u1)

;; Data Maps
(define-map analysts
  { analyst-id: uint }
  {
    address: principal,
    name: (string-ascii 50),
    certification-level: uint,
    verified: bool,
    verification-date: uint,
    active: bool
  }
)

(define-map analyst-by-address
  { address: principal }
  { analyst-id: uint }
)

;; Public Functions

;; Register a new analyst
(define-public (register-analyst (name (string-ascii 50)) (certification-level uint))
  (let ((analyst-id (var-get next-analyst-id)))
    (asserts! (is-none (map-get? analyst-by-address { address: tx-sender })) ERR_ANALYST_EXISTS)
    (asserts! (and (>= certification-level u1) (<= certification-level u5)) ERR_INVALID_CREDENTIALS)

    (map-set analysts
      { analyst-id: analyst-id }
      {
        address: tx-sender,
        name: name,
        certification-level: certification-level,
        verified: false,
        verification-date: u0,
        active: true
      }
    )

    (map-set analyst-by-address
      { address: tx-sender }
      { analyst-id: analyst-id }
    )

    (var-set next-analyst-id (+ analyst-id u1))
    (ok analyst-id)
  )
)

;; Verify an analyst (only contract owner)
(define-public (verify-analyst (analyst-id uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (match (map-get? analysts { analyst-id: analyst-id })
      analyst-data
      (begin
        (map-set analysts
          { analyst-id: analyst-id }
          (merge analyst-data { verified: true, verification-date: block-height })
        )
        (ok true)
      )
      ERR_ANALYST_NOT_FOUND
    )
  )
)

;; Read-only Functions

;; Get analyst information
(define-read-only (get-analyst (analyst-id uint))
  (map-get? analysts { analyst-id: analyst-id })
)

;; Check if analyst is verified
(define-read-only (is-analyst-verified (address principal))
  (match (map-get? analyst-by-address { address: address })
    analyst-ref
    (match (map-get? analysts { analyst-id: (get analyst-id analyst-ref) })
      analyst-data
      (get verified analyst-data)
      false
    )
    false
  )
)

;; Get analyst ID by address
(define-read-only (get-analyst-id (address principal))
  (map-get? analyst-by-address { address: address })
)
