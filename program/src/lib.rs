#![no_std]

use pinocchio::{
    Address, ProgramResult,
    entrypoint::{InstructionContext, MaybeAccount},
    error::ProgramError,
    lazy_program_entrypoint, no_allocator, nostd_panic_handler,
    sysvars::instructions::Instructions,
};

// System program ID.
const SYSTEM_PROGRAM_ID: Address = Address::new_from_array([0u8; 32]);

// Disable the memory allocator.
no_allocator!();
// Use a `no_std` panic handler.
nostd_panic_handler!();
// Process the input lazily.
lazy_program_entrypoint!(process_instruction);

pub fn process_instruction(mut context: InstructionContext) -> ProgramResult {
    let MaybeAccount::Account(account) = context.next_account()? else {
        return Err(ProgramError::NotEnoughAccountKeys);
    };

    let sysvar = Instructions::try_from(&account)?;
    // Load the first top-level instruction.
    let instruction = sysvar.load_instruction_at(0)?;
    // Reject the transaction if the first instruction  is a system program
    // `AdvanceNonceAccount` instruction.
    if instruction.get_program_id() == &SYSTEM_PROGRAM_ID
        && let Some([4, 0, 0, 0]) = instruction.get_instruction_data().get(..4)
    {
        return Err(ProgramError::InvalidArgument);
    }

    Ok(())
}
