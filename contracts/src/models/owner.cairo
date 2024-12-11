use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Owner {
    #[key]
    pub entity_id: u32,
    pub address: ContractAddress,
}
