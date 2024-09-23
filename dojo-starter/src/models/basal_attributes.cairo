use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct BasalAttributes {
    #[key]
    pub entity: ContractAddress,
    pub attributes: u8,  // Assuming 12 attributes as stated
}
