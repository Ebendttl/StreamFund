;; StreamFund: Continuous Funding with Vesting
;; Description:
;; StreamFund enables ongoing crowdfunding with no fixed goals, releasing funds to creators gradually over a vesting period. 
;; Contributors can join anytime while active, with a minimum contribution. Creators claim vested funds periodically and 
;; can deactivate campaigns, halting new contributions while preserving vesting.

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u501))
(define-constant ERR-CAMPAIGN-INACTIVE (err u502))
(define-constant ERR-INSUFFICIENT-AMOUNT (err u503))
(define-constant ERR-NOTHING-TO-CLAIM (err u504))

;; Campaign data: stores core campaign attributes
(define-map Campaigns
  { campaign-id: uint }
  {
    creator: principal,
    total-raised: uint,
    min-contribution: uint,
    vesting-start: uint,
    vesting-duration: uint,
    total-vested: uint,
    active: bool
  }
)

;; Contributions: tracks individual supporter contributions
(define-map Contributions
  { campaign-id: uint, contributor: principal }
  { amount: uint }
)

;; Campaign counter: increments for unique campaign IDs
(define-data-var campaign-counter uint u0)

;; Create a new StreamFund campaign
(define-public (create-campaign (min-contribution uint) (vesting-duration uint))
  (let
    (
      (campaign-id (+ (var-get campaign-counter) u1))
      (start-height block-height)
    )
    (asserts! (> min-contribution u0) ERR-INSUFFICIENT-AMOUNT)
    (asserts! (> vesting-duration u100) ERR-INSUFFICIENT-AMOUNT) ;; Ensures meaningful vesting period
    
    (var-set campaign-counter campaign-id)
    (map-insert Campaigns
      { campaign-id: campaign-id }
      {
        creator: tx-sender,
        total-raised: u0,
        min-contribution: min-contribution,
        vesting-start: start-height,
        vesting-duration: vesting-duration,
        total-vested: u0,
        active: true
      }
    )
    (ok campaign-id)
  )
)

;; Contribute to an active campaign
(define-public (contribute (campaign-id uint) (amount uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (min-amount (get min-contribution campaign))
    )
    (asserts! (get active campaign) ERR-CAMPAIGN-INACTIVE)
    (asserts! (>= amount min-amount) ERR-INSUFFICIENT-AMOUNT)
    
    (match (map-get? Contributions { campaign-id: campaign-id, contributor: tx-sender })
      existing
      (map-set Contributions
        { campaign-id: campaign-id, contributor: tx-sender }
        { amount: (+ (get amount existing) amount) })
      (map-insert Contributions
        { campaign-id: campaign-id, contributor: tx-sender }
        { amount: amount })
    )
    
    (map-set Campaigns
      { campaign-id: campaign-id }
      (merge campaign { total-raised: (+ (get total-raised campaign) amount) })
    )
    
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (ok true)
  )
)

;; Claim vested funds periodically
(define-public (claim-vested (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (creator (get creator campaign))
      (total-raised (get total-raised campaign))
      (vesting-start (get vesting-start campaign))
      (vesting-duration (get vesting-duration campaign))
      (total-vested (get total-vested campaign))
      (current-height block-height)
      (elapsed (if (> current-height vesting-start) (- current-height vesting-start) u0))
      (vested-amount (/ (* total-raised elapsed) vesting-duration))
      (claimable (if (> vested-amount total-vested) (- vested-amount total-vested) u0))
    )
    (asserts! (is-eq tx-sender creator) ERR-NOT-AUTHORIZED)
    (asserts! (get active campaign) ERR-CAMPAIGN-INACTIVE)
    (asserts! (> claimable u0) ERR-NOTHING-TO-CLAIM)
    
    (map-set Campaigns
      { campaign-id: campaign-id }
      (merge campaign { total-vested: (+ total-vested claimable) })
    )
    
    (print {
      event: "vested-claimed",
      campaign-id: campaign-id,
      amount: claimable,
      creator: creator,
      block-height: current-height
    })
    
    (try! (as-contract (stx-transfer? claimable tx-sender creator)))
    (ok true)
  )
)

;; Read-only functions for transparency
(define-read-only (get-campaign (campaign-id uint))
  (map-get? Campaigns { campaign-id: campaign-id })
)

(define-read-only (get-contribution (campaign-id uint) (contributor principal))
  (map-get? Contributions { campaign-id: campaign-id, contributor: contributor })
)

;; Deactivate campaign
(define-public (deactivate-campaign (campaign-id uint))
  (let
    (
      (campaign (unwrap! (map-get? Campaigns { campaign-id: campaign-id }) ERR-CAMPAIGN-NOT-FOUND))
      (creator (get creator campaign))
      (total-raised (get total-raised campaign))
      (min-contribution (get min-contribution campaign))
      (vesting-start (get vesting-start campaign))
      (vesting-duration (get vesting-duration campaign))
      (total-vested (get total-vested campaign))
      (current-height block-height)
      (is-active (get active campaign))
      (elapsed (if (> current-height vesting-start) (- current-height vesting-start) u0))
      (vested-so-far (/ (* total-raised elapsed) vesting-duration))
      (remaining-to-vest (if (> vested-so-far total-vested) (- vested-so-far total-vested) u0))
    )
    ;; Authorization and state validation
    (asserts! (is-eq tx-sender creator) ERR-NOT-AUTHORIZED)
    (asserts! is-active ERR-CAMPAIGN-INACTIVE)
    
    ;; Update campaign status to inactive
    (map-set Campaigns
      { campaign-id: campaign-id }
      (merge campaign { active: false })
    )
    
    ;; Detailed logging of deactivation event
    (print {
      event: "campaign-deactivated",
      campaign-id: campaign-id,
      creator: creator,
      total-raised: total-raised,
      min-contribution: min-contribution,
      vesting-start: vesting-start,
      vesting-duration: vesting-duration,
      total-vested: total-vested,
      vested-so-far: vested-so-far,
      remaining-to-vest: remaining-to-vest,
      deactivation-height: current-height
    })
    
    ;; Return success
    (ok true)
  )
)
