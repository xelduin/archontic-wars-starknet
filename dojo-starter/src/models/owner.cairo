use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct Owner {
    #[key]
    pub entity: ContractAddress,
    pub owner_address: ContractAddress,
}
