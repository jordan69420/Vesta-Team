pragma solidity ^0.8.4;


contract DebtLedger {
    

//  __  __           _             _____                          _     _                       
// |  \/  |   __ _  (_)  _ __     |  ___|  _   _   _ __     ___  | |_  (_)   ___    _ __    ___ 
// | |\/| |  / _` | | | | '_ \    | |_    | | | | | '_ \   / __| | __| | |  / _ \  | '_ \  / __|
// | |  | | | (_| | | | | | | |   |  _|   | |_| | | | | | | (__  | |_  | | | (_) | | | | | \__ \
// |_|  |_|  \__,_| |_| |_| |_|   |_|      \__,_| |_| |_|  \___|  \__| |_|  \___/  |_| |_| |___/
                                                                                              


    //Keeps Track of Debts, Debtors and Creditors
    mapping (address => mapping (uint256 => DTR)) DebtTracker;
    mapping (address => uint) DebtCount;
    
    struct DTR {
        address Creditor;
        address Debtor;
        uint256 InitialValue;
        uint256 UnPaidValue;
        bool Validity;
        uint DebtId;
        bool paid;
        uint256 ColPercent;
    }
    mapping (address => uint256) paid_loans;
    mapping (address => uint256) collateral;
    mapping (address => uint256) used_collateral;
    
    function NewDebt(address Debtor, uint256 DebtAmount, uint256 collateral_percentage) public returns(address, uint256){
        // Variable Setting
        if (collateral[msg.sender] - used_collateral[msg.sender] >= DebtAmount * collateral_percentage / 100) {
            uint256 ID = (DebtCount[msg.sender] + 1);
            // Modifiers
            DebtTracker[msg.sender][ID] = DTR(msg.sender,Debtor,DebtAmount,DebtAmount,false,ID,false,collateral_percentage);
            DebtCount[msg.sender] = DebtCount[msg.sender] + 1;
            used_collateral[msg.sender] += DebtAmount * 3/4;
            //Return Data
            return (Debtor, DebtAmount);
        }
        else {
            revert();
        }
    }
    
    function ConfirmDebt(address debter, uint ID, uint256 collateral_percentage) public payable returns(address, uint256, bool){
        require (msg.sender == DebtTracker[debter][ID].Creditor);
        require (collateral_percentage == DebtTracker[debter][ID].ColPercent);
        require (DebtTracker[DebtTracker[debter][ID].Creditor][ID].Validity == true);
        if (msg.value >= DebtTracker[debter][ID].UnPaidValue) {
            payable(debter).transfer(DebtTracker[debter][ID].UnPaidValue);
            return (debter, ID, true);
        }
        else {
            revert();
        }
        
        
    }
    
    function ViewDebt(address Creditor, uint ID) public view returns(address Lender, address Borrower, uint256 Amount, uint256 UnpaidAmount, bool Confirmed, uint DebtIdentifier){
        return
        (DebtTracker[Creditor][ID].Creditor,
        DebtTracker[Creditor][ID].Debtor,
        DebtTracker[Creditor][ID].InitialValue,
        DebtTracker[Creditor][ID].UnPaidValue,
        DebtTracker[Creditor][ID].Validity,
        DebtTracker[Creditor][ID].DebtId);
        
    }
    
    function make_payment(address Creditor, uint ID, uint amount_to_pay) public returns(bool success){
        if (collateral[msg.sender] >= amount_to_pay) {
            if (DebtTracker[Creditor][ID].paid == false) {
                address payable lender = payable(DebtTracker[Creditor][ID].Creditor);
                lender.transfer(amount_to_pay - 0.001 ether); //compensate for gas fee, and claim a small amount to ofset larger fees in the future
                DebtTracker[Creditor][ID].UnPaidValue = DebtTracker[Creditor][ID].UnPaidValue - amount_to_pay;
                if (DebtTracker[Creditor][ID].UnPaidValue >= 0) {
                    DebtTracker[Creditor][ID].paid = true;
                    paid_loans[msg.sender] += 1;
                }
                return (true);
            }
        }
        else {
            return false;
        }
    }
    function seeLoans(address Borrower) public view returns (uint256 loans_paid) {
        return paid_loans[Borrower];
    }
    function deposit_collateral() public payable returns (bool success) {
        if (msg.value >= 0) {
            collateral[msg.sender] += msg.value;
            return true;
        }
        else 
        {
            return false;
        }
    }
}

