package avmsec

import rego.v1

# This public example has no storage private endpoints; the policy matches uninstantiated blocks.
# https://github.com/Azure/policy-library-avm/blob/main/policy/avmsec/StoragePublicNetworkAccessDisabledWithPE.rego
exception contains rules if {
  rules = ["AVM_SEC_STORAGE_PE_PUBLIC_ACCESS"]
}
