// -*- tab-width: 4; Mode: C++; c-basic-offset: 4; indent-tabs-mode: t -*-

// Copyright 2012 Andrew Tridgell, all rights reserved.

//	This library is free software; you can redistribute it and / or
//	modify it under the terms of the GNU Lesser General Public
//	License as published by the Free Software Foundation; either
//	version 2.1 of the License, or (at your option) any later version.

#ifndef QUATERNION_H
#define QUATERNION_H

#include <math.h>

class Quaternion
{
public:
	float q1, q2, q3, q4;

	// constructor
	Quaternion() { q1 = 1; q2 = q3 = q4 = 0; }

	// setting constructor
	Quaternion(const float _q1, const float _q2, const float _q3, const float _q4):
	q1(_q1), q2(_q2), q3(_q3), q4(_q4) {}

	// function call operator
	void operator ()(const float _q1, const float _q2, const float _q3, const float _q4)
	{ q1 = _q1; q2 = _q2; q3 = _q3; q4 = _q4; }

	// check if any elements are NAN
	bool is_nan(void)
	{   return isnan(q1) || isnan(q2) || isnan(q3) || isnan(q4); }

};
#endif // QUATERNION_H
