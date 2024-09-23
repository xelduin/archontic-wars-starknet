use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct LooshBalance {
    #[key]
    pub entity: ContractAddress,
    pub loosh: u128,
}
