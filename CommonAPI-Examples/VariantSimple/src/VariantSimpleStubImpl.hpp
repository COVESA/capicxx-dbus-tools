/* Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef VARIANTSIMPLESTUBIMPL_H_
#define VARIANTSIMPLESTUBIMPL_H_

#include <v0/commonapi/examples/VariantSimpleStubDefault.hpp>

class VariantSimpleStubImpl : public v0::commonapi::examples::VariantSimpleStubDefault {
public:
    VariantSimpleStubImpl();
    virtual ~VariantSimpleStubImpl();

    virtual void callMe(const std::shared_ptr<CommonAPI::ClientId> _client, std::string _strArg, v0::commonapi::examples::VariantSimple::SampleUnion _varArg, callMeReply_t _reply);
    virtual void getProperties(const std::shared_ptr<CommonAPI::ClientId> _client, getPropertiesReply_t _reply);

    virtual void callMe(const std::shared_ptr<CommonAPI::ClientId> _client, int32_t _intInArg, callMeReply_t _reply);

private:
    int32_t callMeCount;
};

#endif /* VARIANTSIMPLESTUBIMPL_H_ */
