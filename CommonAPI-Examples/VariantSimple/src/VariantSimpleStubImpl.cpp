/* Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "VariantSimpleStubImpl.hpp"

VariantSimpleStubImpl::VariantSimpleStubImpl() : VariantSimpleStubDefault(), callMeCount(0) {
	setStatusAttribute("initializing");
}

VariantSimpleStubImpl::~VariantSimpleStubImpl() {
}

void VariantSimpleStubImpl::callMe(const std::shared_ptr<CommonAPI::ClientId> _client, std::string _strArg, v0_1::commonapi::examples::VariantSimple::SampleUnion _varArg, callMeReply_t _reply) {

	static int32_t called = 0;
	if (_varArg.isType<int>()) {
		std::cout << "callMe strArg: " << _strArg << " varArg (int): " << _varArg.get<int>() << std::endl;;
	}
	else if (_varArg.isType<std::string>()) {
		std::cout << "callMe strArg: " << _strArg << " varArg (int): " << _varArg.get<std::string>() << std::endl;;
	}
	_reply(std::string("got it"), ++called);
}

void VariantSimpleStubImpl::getProperties(const std::shared_ptr<CommonAPI::ClientId> _client, getPropertiesReply_t _reply) {
	v0_1::commonapi::examples::VariantSimple::tPropertiesDict properties;

	properties["test"] = v0_1::commonapi::examples::VariantSimple::SampleUnion(45);
	properties["hello"] = v0_1::commonapi::examples::VariantSimple::SampleUnion(std::string("world"));
    _reply(properties);
}

void VariantSimpleStubImpl::callMe(const std::shared_ptr<CommonAPI::ClientId> _client, int32_t _intInArg, callMeReply_t _reply) {
	++callMeCount;
	const std::string & strOut = "got it";
	_reply(strOut, v0_1::commonapi::examples::VariantSimple::SampleUnion(callMeCount));
}
