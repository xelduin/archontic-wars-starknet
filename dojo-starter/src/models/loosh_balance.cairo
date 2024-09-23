use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct LooshBalance {
    #[key]
    pub address: ContractAddress,
    pub balance: u128,
}

