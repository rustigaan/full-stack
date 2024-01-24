//! Generated module. Do not edit.

use anyhow::Result;
use dendrite::auth::dendrite_config::PublicKey;

pub fn init() -> Result<()> {
    let public_key = PublicKey {
        name: "jeroen@aenea.entreact.com".to_string(),
        public_key: "AAAAB3NzaC1yc2EAAAABIwAAAQEAzu3J6nPQjN71F7rkvuBoy3DuoRK144z9CrpuNuU9U86rHl33mTSCiOaWFXvArR5nUpG8Oe1qRzGnHqczLP74L8CGXmq9rmh3zXGS8goudPx9iAc1dpZSGumnffY1/o/PKKU6mEudY/KIP4ZRxZZ8l4moUCH9xwip+YIEHiUm0XGVJLoBUc8Gx/v1nzZGdKgbCMBx78SizF6rIN77pcHqCiFa5j7p7QcGwa7pPmZw7Mwuqnu7/qpRdyqmnu1q4h+f+UjsReEUH5MEWPCzhxCLOy3iN7qunWavxNjWNHMa6/JjAvyilO6FaHYkcn5uQCvM+wleMUtXuLdNx/gpVUGsHQ==".to_string(),
    };
    dendrite::auth::unchecked_set_public_key(public_key.clone())?;
    dendrite::auth::unchecked_set_key_manager(public_key.clone())?;
    Ok(())
}
