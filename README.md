# StartupEscrow Smart Contract

A multi-signature escrow smart contract built on the Stacks blockchain using Clarity. This contract enables secure startup funding management by requiring consensus between investors and founders before releasing funds.

## 🌟 Features

- **Multi-Signature Security**: Configurable signature requirements for fund releases
- **Role-Based Access**: Separate roles for founders and investors
- **Proposal System**: Structured withdrawal process with descriptions
- **Escrow Management**: Secure fund deposits and tracked balances
- **Transparency**: All actions are recorded on-chain
- **Flexible Administration**: Owner can manage participants and signature requirements

## 🏗️ Architecture

The contract implements these core components:

- **Participant Management**: Track authorized founders and investors
- **Proposal System**: Create, sign, and execute withdrawal requests
- **Multi-Signature Logic**: Require minimum signatures before fund release
- **Balance Tracking**: Monitor deposited and withdrawn funds
- **Access Control**: Role-based permissions and owner administration

## 📋 Prerequisites

- Stacks blockchain environment
- Clarity smart contract deployment capability
- STX tokens for contract interactions

## 🚀 Deployment

1. Deploy the contract to Stacks blockchain
2. Initialize with founders, investors, and signature requirements
3. Participants can begin depositing funds and creating proposals

## 🔧 Core Functions

### Administrative Functions

#### `initialize(founders, investors, min-signatures)`
Sets up the escrow with initial participants and signature requirements.

**Parameters:**
- `founders`: List of founder principals (max 10)
- `investors`: List of investor principals (max 10)  
- `min-signatures`: Minimum signatures required for proposal execution

**Access:** Contract owner only

```clarity
(contract-call? .startup-escrow initialize 
    (list 'SP1234... 'SP5678...) 
    (list 'SP9ABC... 'SPDEF...) 
    u2)
```

#### `add-participant(participant, role)`
Adds a new participant to the escrow.

**Parameters:**
- `participant`: Principal address to add
- `role`: Role string ("founder" or "investor")

**Access:** Contract owner only

#### `remove-participant(participant)`
Removes a participant from the escrow.

**Access:** Contract owner only

#### `update-required-signatures(new-requirement)`
Updates the minimum signature requirement.

**Access:** Contract owner only

### Core Escrow Functions

#### `deposit(amount)`
Deposits STX tokens into the escrow.

**Parameters:**
- `amount`: Amount of STX to deposit (in microSTX)

**Access:** Any user

**Returns:** Deposited amount

```clarity
(contract-call? .startup-escrow deposit u1000000) ;; Deposit 1 STX
```

#### `create-proposal(recipient, amount, description)`
Creates a new withdrawal proposal.

**Parameters:**
- `recipient`: Principal to receive the funds
- `amount`: Amount to withdraw (in microSTX)
- `description`: Description of the withdrawal purpose (max 500 chars)

**Access:** Authorized participants only

**Returns:** Proposal ID

```clarity
(contract-call? .startup-escrow create-proposal 
    'SP1234... 
    u500000 
    "Marketing campaign funding")
```

#### `sign-proposal(proposal-id)`
Signs approval for a withdrawal proposal.

**Parameters:**
- `proposal-id`: ID of the proposal to sign

**Access:** Authorized participants only

**Restrictions:**
- Cannot sign the same proposal twice
- Cannot sign executed proposals

```clarity
(contract-call? .startup-escrow sign-proposal u1)
```

#### `execute-proposal(proposal-id)`
Executes a proposal that has sufficient signatures.

**Parameters:**
- `proposal-id`: ID of the proposal to execute

**Access:** Authorized participants only

**Requirements:**
- Proposal must have minimum required signatures
- Proposal must not be already executed
- Sufficient balance must be available

```clarity
(contract-call? .startup-escrow execute-proposal u1)
```

## 📖 Read-Only Functions

### `get-balance()`
Returns the current escrow balance.

### `get-proposal(proposal-id)`
Returns proposal details including recipient, amount, description, and execution status.

### `get-signature-count(proposal-id)`
Returns the number of signatures for a specific proposal.

### `has-signed(proposal-id, signer)`
Checks if a specific user has signed a proposal.

### `is-participant-read(user)`
Checks if a user is an authorized participant.

### `get-participant-role(user)`
Returns the role of a participant ("founder" or "investor").

### `get-required-signatures()`
Returns the current signature requirement.

### `get-proposal-counter()`
Returns the total number of proposals created.

## 🔒 Security Features

- **Double-Signature Prevention**: Users cannot sign the same proposal twice
- **Balance Validation**: Proposals cannot exceed available balance
- **Role-Based Access**: Only authorized participants can create/sign proposals
- **Execution Protection**: Proposals cannot be executed multiple times
- **Owner Controls**: Critical functions restricted to contract owner

## ⚠️ Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | `err-owner-only` | Function restricted to contract owner |
| 101 | `err-not-authorized` | User not authorized for this action |
| 102 | `err-already-signed` | User already signed this proposal |
| 103 | `err-insufficient-balance` | Not enough funds in escrow |
| 104 | `err-invalid-amount` | Invalid amount specified |
| 105 | `err-proposal-not-found` | Proposal ID does not exist |
| 106 | `err-already-executed` | Proposal already executed |
| 107 | `err-insufficient-signatures` | Not enough signatures to execute |
| 108 | `err-invalid-participant` | User is not a valid participant |

## 📝 Usage Example

```clarity
;; 1. Initialize the contract
(contract-call? .startup-escrow initialize 
    (list 'SP1FOUNDER1 'SP2FOUNDER2) 
    (list 'SP3INVESTOR1 'SP4INVESTOR2) 
    u2)

;; 2. Deposit funds
(contract-call? .startup-escrow deposit u5000000) ;; 5 STX

;; 3. Create a proposal
(contract-call? .startup-escrow create-proposal 
    'SP5VENDOR 
    u1000000 
    "Website development payment")

;; 4. Sign the proposal (from multiple participants)
(contract-call? .startup-escrow sign-proposal u1)

;; 5. Execute when enough signatures collected
(contract-call? .startup-escrow execute-proposal u1)
```

## 🔄 Typical Workflow

1. **Setup**: Contract owner initializes with founders and investors
2. **Funding**: Participants deposit STX into the escrow
3. **Proposal**: Any participant creates a withdrawal proposal
4. **Consensus**: Participants sign the proposal to show approval
5. **Execution**: Once minimum signatures reached, proposal can be executed
6. **Transfer**: Funds are released to the specified recipient

## 🛡️ Best Practices

- Set appropriate signature requirements based on your governance model
- Use descriptive proposal descriptions for transparency
- Regularly monitor proposal status and signatures
- Keep participant lists updated as team composition changes
- Test all functions on testnet before mainnet deployment
