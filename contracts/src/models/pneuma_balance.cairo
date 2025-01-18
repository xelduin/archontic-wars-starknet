use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct PneumaBalance {
    #[key]
    pub address: ContractAddress,
    pub balance: u128,
}

