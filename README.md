StreamFund: Continuous Funding Platform
=======================================

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

StreamFund is a decentralized continuous funding platform with vesting capabilities implemented as a smart contract on the Stacks blockchain. The platform enables creators to receive ongoing crowdfunding with gradual fund release through vesting mechanisms.

Table of Contents
-----------------

- Overview
- Architecture
- Key Features
- Smart Contracts
  - StreamFund Contract
  - Governance Token Contract
- Usage
  - For Creators
  - For Contributors
  - For Governance Token Holders
- Technical Details
- Security Considerations
- Contributing
- License

Overview
--------

StreamFund provides a flexible funding model where creators can receive continuous financial support without fixed goals. Funds are released gradually over a vesting period, ensuring sustainable project development. Additionally, the platform includes a governance system that enables token holders to participate in decision-making processes.

Architecture
------------

The platform consists of two main components:

1.  **StreamFund Contract** - Manages campaign creation, contributions, and vesting schedules
2.  **Governance Token Contract** - Handles governance mechanisms, including proposal creation and voting

Key Features
------------

### StreamFund

-   **Continuous Funding:** No fixed funding goals, allowing campaigns to receive funding indefinitely
-   **Gradual Fund Release:** Vesting mechanism that releases funds to creators over time
-   **Minimum Contribution:** Configurable minimum contribution amount per campaign
-   **Campaign Deactivation:** Ability to halt new contributions while preserving the vesting schedule
-   **Transparent Fund Tracking:** Public functions to monitor campaign metrics

### Governance

-   **Token-Based Governance:** Decision-making through proposal and voting mechanisms
-   **Role-Based Access Control:** Admin and minter roles with specific permissions
-   **Transfer Limits:** Daily transfer limits to prevent token dumping
-   **Secure Token Management:** Functions for minting and burning tokens

Smart Contracts
---------------

### StreamFund Contract

#### Constants

```
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-CAMPAIGN-NOT-FOUND (err u501))
(define-constant ERR-CAMPAIGN-INACTIVE (err u502))
(define-constant ERR-INSUFFICIENT-AMOUNT (err u503))
(define-constant ERR-NOTHING-TO-CLAIM (err u504))

```

#### Data Maps

-   `Campaigns`: Stores campaign attributes
-   `Contributions`: Tracks individual contributions
-   `campaign-counter`: Manages unique campaign IDs

#### Public Functions

-   `create-campaign`: Create a new funding campaign
-   `contribute`: Contribute to an active campaign
-   `claim-vested`: Claim vested funds as a campaign creator
-   `deactivate-campaign`: Deactivate a campaign
-   `get-campaign`: Get details of a specific campaign (read-only)
-   `get-contribution`: Get details of a contributor's contribution (read-only)

### Governance Token Contract

#### Constants

```
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INSUFFICIENT-BALANCE (err u101))
(define-constant ERR-INVALID-PROPOSAL (err u102))
(define-constant ERR-ALREADY-VOTED (err u103))
(define-constant ERR-TRANSFER-LIMIT-EXCEEDED (err u104))
(define-constant ERR-INVALID-TRANSFER-AMOUNT (err u105))
(define-constant DAILY-TRANSFER-LIMIT u10000)
(define-constant BLOCKS-PER-DAY u144)

```

#### Data Maps

-   `user-roles`: Tracks admin and minter roles
-   `proposals`: Stores proposal information
-   `proposal-votes`: Tracks votes on proposals
-   `transfer-limits`: Manages user transfer limits
-   `last-proposal-id`: Tracks the latest proposal ID

#### Public Functions

-   `mint-tokens`: Mint new governance tokens
-   `burn-tokens`: Burn governance tokens
-   `set-user-role`: Assign or revoke roles
-   `create-proposal`: Create a new governance proposal
-   `vote-on-proposal`: Vote on an existing proposal
-   `safe-transfer`: Transfer tokens with additional checks
-   `set-user-transfer-limit`: Customize transfer limits for users

Usage
-----

### For Creators

1.  **Create a Campaign**

    ```
    (contract-call? .streamfund create-campaign u100 u10000)

    ```

    This creates a campaign with a minimum contribution of 100 STX and a vesting duration of 10,000 blocks.

2.  **Claim Vested Funds**

    ```
    (contract-call? .streamfund claim-vested u1)

    ```

    This claims the vested funds from campaign #1.

3.  **Deactivate a Campaign**

    ```
    (contract-call? .streamfund deactivate-campaign u1)

    ```

    This deactivates campaign #1, preventing new contributions.

### For Contributors

1.  **Contribute to a Campaign**

    ```
    (contract-call? .streamfund contribute u1 u500)

    ```

    This contributes 500 STX to campaign #1.

2.  **Check Contribution**

    ```
    (contract-call? .streamfund get-contribution u1 tx-sender)

    ```

    This returns the contribution details for the current user to campaign #1.

### For Governance Token Holders

1.  **Create a Proposal**

    ```
    (contract-call? .governance create-proposal "Increase Daily Transfer Limit" "Increase the daily transfer limit from 10,000 to 15,000 tokens")

    ```

2.  **Vote on a Proposal**

    ```
    (contract-call? .governance vote-on-proposal u1 true)

    ```

    This casts a "for" vote on proposal #1.

3.  **Transfer Tokens**

    ```
    (contract-call? .governance safe-transfer u1000 tx-sender 'STCREAMDAFASDFSADF)

    ```

    This safely transfers 1,000 tokens to another account.

Technical Details
-----------------

### Vesting Mechanism

The vesting mechanism in StreamFund operates based on block height. The amount vested is calculated as:

```
vested-amount = (total-raised * elapsed-blocks) / vesting-duration

```

### Transfer Limits

To prevent market manipulation, the governance token contract implements daily transfer limits calculated on a per-block basis:

```
blocks-per-day = 144 (assuming ~10 minute block times)

```

### Role-Based Access

The governance contract implements role-based access control with two key roles:

-   **Admin**: Can mint tokens and manage user roles
-   **Minter**: Can mint tokens

Security Considerations
-----------------------

1.  **Authorization Checks**: All sensitive functions include proper authorization checks
2.  **Balance Validation**: Operations that involve tokens validate balances before execution
3.  **Transfer Limits**: Governance token transfers are limited to prevent market manipulation
4.  **Immutable Constants**: Critical values are defined as constants to prevent unauthorized changes

Contributing
------------

Contributions are welcome! Please feel free to submit a Pull Request.

1.  Fork the repository
2.  Create your feature branch (`git checkout -b feature/amazing-feature`)
3.  Commit your changes (`git commit -m 'Add some amazing feature'`)
4.  Push to the branch (`git push origin feature/amazing-feature`)
5.  Open a Pull Request

License
-------

This project is licensed under the MIT License - see the LICENSE file for details.
