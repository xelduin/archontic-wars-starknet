use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Owner {
    #[key]
    pub entity: u32,
    pub owner_address: ContractAddress,
}
