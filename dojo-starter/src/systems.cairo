pub mod creation {
    pub mod contracts;
}

pub mod authority {
    pub mod contracts;
    #[cfg(test)]
    mod tests;
}

pub mod movement {
    pub mod contracts;
}

pub mod dust {
    pub mod contracts;
}

pub mod loosh {
    pub mod contracts;
}

pub mod mass {
    pub mod contracts;
}
