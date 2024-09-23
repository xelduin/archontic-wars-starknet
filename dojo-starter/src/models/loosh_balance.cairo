use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct LooshBalance {
    #[key]
    pub entity: u32,
    pub loosh: u128,
}
