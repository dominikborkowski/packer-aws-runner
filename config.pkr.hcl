packer {
    required_version = ">= 1.9.0"

    required_plugins {
        amazon = {
            version = ">= 0.0.1"
            source  = "github.com/hashicorp/amazon"
        }
        goss = {
            version = "~> 3"
            source  = "github.com/YaleUniversity/goss"
        }
    }
}
