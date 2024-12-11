#[derive(Serde, Copy, Drop, Introspect)]
pub enum BasalAttributesType {
    Sense,
}

#[derive(Copy, Drop, Serde)]
#[dojo::model]
pub struct BasalAttributes {
    #[key]
    pub entity_id: u32,
    pub attributes: u8, // Assuming 12 attributes as stated
}

#[generate_trait]
impl BasalAttributesImpl of BasalAttributesTrait {
    fn get_attribute_value(self: BasalAttributes, attribute_type: BasalAttributesType) -> u8 {
        return self.attributes;
    }

    fn update_attribute(
        self: BasalAttributes, attribute_type: BasalAttributesType, attribute_value: u8
    ) -> BasalAttributes {
        assert(attribute_value <= 100, 'attribute over 100');
        return BasalAttributes { entity_id: self.entity_id, attributes: attribute_value };
    }
}
