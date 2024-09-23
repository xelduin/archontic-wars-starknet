use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Mass {
    #[key]
    pub entity: ContractAddress,
    pub mass: u64,
}
