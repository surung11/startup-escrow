;; StartupEscrow - Multi-signature escrow for startup funding
;; Requires consensus between investors and founders for fund releases

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-signed (err u102))
(define-constant err-insufficient-balance (err u103))
(define-constant err-invalid-amount (err u104))
(define-constant err-proposal-not-found (err u105))
(define-constant err-already-executed (err u106))
(define-constant err-insufficient-signatures (err u107))
(define-constant err-invalid-participant (err u108))

;; Data Variables
(define-data-var total-balance uint u0)
(define-data-var proposal-counter uint u0)
(define-data-var required-signatures uint u2)

;; Data Maps
(define-map participants principal bool)
(define-map participant-roles principal (string-ascii 20))

(define-map proposals
    uint
    {
        recipient: principal,
        amount: uint,
        description: (string-ascii 500),
        executed: bool,
        created-by: principal,
        created-at: uint
    }
)

(define-map proposal-signatures
    { proposal-id: uint, signer: principal }
    bool
)

(define-map proposal-signature-count uint uint)

;; Private Functions
(define-private (is-participant (user principal))
    (default-to false (map-get? participants user))
)

(define-private (increment-proposal-counter)
    (let ((current-counter (var-get proposal-counter)))
        (var-set proposal-counter (+ current-counter u1))
        (+ current-counter u1)
    )
)

;; Public Functions

;; Initialize contract with participants
(define-public (initialize (founders (list 10 principal)) (investors (list 10 principal)) (min-signatures uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (> min-signatures u0) err-invalid-amount)
        
        ;; Add founders
        (map add-founder founders)
        
        ;; Add investors  
        (map add-investor investors)
        
        ;; Set required signatures
        (var-set required-signatures min-signatures)
        (ok true)
    )
)

;; Helper function to add a founder
(define-private (add-founder (founder principal))
    (begin
        (map-set participants founder true)
        (map-set participant-roles founder "founder")
        true
    )
)

;; Helper function to add an investor
(define-private (add-investor (investor principal))
    (begin
        (map-set participants investor true)  
        (map-set participant-roles investor "investor")
        true
    )
)

;; Deposit funds to escrow
(define-public (deposit (amount uint))
    (begin
        (asserts! (> amount u0) err-invalid-amount)
        (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
        (var-set total-balance (+ (var-get total-balance) amount))
        (ok amount)
    )
)

;; Create a withdrawal proposal
(define-public (create-proposal (recipient principal) (amount uint) (description (string-ascii 500)))
    (let (
        (proposal-id (increment-proposal-counter))
        (current-balance (var-get total-balance))
    )
        (asserts! (is-participant tx-sender) err-not-authorized)
        (asserts! (> amount u0) err-invalid-amount)
        (asserts! (<= amount current-balance) err-insufficient-balance)
        
        (map-set proposals proposal-id {
            recipient: recipient,
            amount: amount,
            description: description,
            executed: false,
            created-by: tx-sender,
            created-at: block-height
        })
        
        (map-set proposal-signature-count proposal-id u0)
        (ok proposal-id)
    )
)

;; Sign a proposal
(define-public (sign-proposal (proposal-id uint))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
        (already-signed (default-to false (map-get? proposal-signatures { proposal-id: proposal-id, signer: tx-sender })))
        (current-signatures (default-to u0 (map-get? proposal-signature-count proposal-id)))
    )
        (asserts! (is-participant tx-sender) err-not-authorized)
        (asserts! (not already-signed) err-already-signed)
        (asserts! (not (get executed proposal)) err-already-executed)
        
        ;; Record the signature
        (map-set proposal-signatures { proposal-id: proposal-id, signer: tx-sender } true)
        (map-set proposal-signature-count proposal-id (+ current-signatures u1))
        
        (ok true)
    )
)

;; Execute a proposal if it has enough signatures
(define-public (execute-proposal (proposal-id uint))
    (let (
        (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
        (signature-count (default-to u0 (map-get? proposal-signature-count proposal-id)))
        (required-sigs (var-get required-signatures))
        (proposal-amount (get amount proposal))
        (proposal-recipient (get recipient proposal))
    )
        (asserts! (is-participant tx-sender) err-not-authorized)
        (asserts! (not (get executed proposal)) err-already-executed)
        (asserts! (>= signature-count required-sigs) err-insufficient-signatures)
        (asserts! (<= proposal-amount (var-get total-balance)) err-insufficient-balance)
        
        ;; Mark proposal as executed
        (map-set proposals proposal-id (merge proposal { executed: true }))
        
        ;; Transfer funds
        (try! (as-contract (stx-transfer? proposal-amount tx-sender proposal-recipient)))
        
        ;; Update balance
        (var-set total-balance (- (var-get total-balance) proposal-amount))
        
        (ok proposal-amount)
    )
)

;; Add new participant (only owner)
(define-public (add-participant (participant principal) (role (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set participants participant true)
        (map-set participant-roles participant role)
        (ok true)
    )
)

;; Remove participant (only owner)
(define-public (remove-participant (participant principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-delete participants participant)
        (map-delete participant-roles participant)
        (ok true)
    )
)

;; Update required signatures (only owner)
(define-public (update-required-signatures (new-requirement uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)  
        (asserts! (> new-requirement u0) err-invalid-amount)
        (var-set required-signatures new-requirement)
        (ok true)
    )
)

;; Read-only functions

;; Get contract balance
(define-read-only (get-balance)
    (var-get total-balance)
)

;; Get proposal details
(define-read-only (get-proposal (proposal-id uint))
    (map-get? proposals proposal-id)
)

;; Get proposal signature count
(define-read-only (get-signature-count (proposal-id uint))
    (default-to u0 (map-get? proposal-signature-count proposal-id))
)

;; Check if user signed a proposal
(define-read-only (has-signed (proposal-id uint) (signer principal))
    (default-to false (map-get? proposal-signatures { proposal-id: proposal-id, signer: signer }))
)

;; Check if user is participant
(define-read-only (is-participant-read (user principal))
    (default-to false (map-get? participants user))
)

;; Get participant role
(define-read-only (get-participant-role (user principal))
    (map-get? participant-roles user)
)

;; Get required signatures
(define-read-only (get-required-signatures)
    (var-get required-signatures)
)

;; Get current proposal counter
(define-read-only (get-proposal-counter)
    (var-get proposal-counter)
)