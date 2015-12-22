module dlangui.core.math3d;

import std.math;

/// 3 dimensional vector
struct vec3 {
	union {
		float[3] vec;
		struct {
			float x;
			float y;
			float z;
		}
	}
	//@property ref float x() { return vec[0]; }
	//@property ref float y() { return vec[1]; }
	//@property ref float z() { return vec[2]; }
	alias r = x;
	alias g = y;
	alias b = z;
	this(float[3] v) {
		vec = v;
	}
	this(const vec3 v) {
		vec = v.vec;
	}
	this(float x, float y, float z) {
		vec[0] = x;
		vec[1] = y;
		vec[2] = z;
	}
	ref vec3 opAssign(float[3] v) {
		vec = v;
		return this;
	}
	ref vec3 opAssign(vec3 v) {
		vec = v.vec;
		return this;
	}
	ref vec3 opAssign(float x, float y, float z) {
		vec[0] = x;
		vec[1] = y;
		vec[2] = z;
		return this;
	}
	/// fill all components of vector with specified value
	ref vec3 clear(float v) {
		vec[0] = vec[1] = vec[2] = v;
		return this;
	}
	/// add value to all components of vector
	ref vec3 add(float v) {
		vec[0] += v;
		vec[1] += v;
		vec[2] += v;
		return this;
	}
	/// multiply all components of vector by value
	ref vec3 mul(float v) {
		vec[0] *= v;
		vec[1] *= v;
		vec[2] *= v;
		return this;
	}
	/// subtract value from all components of vector
	ref vec3 sub(float v) {
		vec[0] -= v;
		vec[1] -= v;
		vec[2] -= v;
		return this;
	}
	/// divide all components of vector by value
	ref vec3 div(float v) {
		vec[0] /= v;
		vec[1] /= v;
		vec[2] /= v;
		return this;
	}
	/// add components of another vector to corresponding components of this vector
	ref vec3 add(vec3 v) {
		vec[0] += v.vec[0];
		vec[1] += v.vec[1];
		vec[2] += v.vec[2];
		return this;
	}
	/// multiply components of this vector  by corresponding components of another vector
	ref vec3 mul(vec3 v) {
		vec[0] *= v.vec[0];
		vec[1] *= v.vec[1];
		vec[2] *= v.vec[2];
		return this;
	}
	/// subtract components of another vector from corresponding components of this vector
	ref vec3 sub(vec3 v) {
		vec[0] -= v.vec[0];
		vec[1] -= v.vec[1];
		vec[2] -= v.vec[2];
		return this;
	}
	/// divide components of this vector  by corresponding components of another vector
	ref vec3 div(vec3 v) {
		vec[0] /= v.vec[0];
		vec[1] /= v.vec[1];
		vec[2] /= v.vec[2];
		return this;
	}

	/// add value to all components of vector
	vec3 opBinary(string op : "+")(float v) const {
		vec3 res = this;
		res.vec[0] += v;
		res.vec[1] += v;
		res.vec[2] += v;
		return res;
	}
	/// multiply all components of vector by value
	vec3 opBinary(string op : "*")(float v) const {
		vec3 res = this;
		res.vec[0] *= v;
		res.vec[1] *= v;
		res.vec[2] *= v;
		return res;
	}
	/// subtract value from all components of vector
	vec3 opBinary(string op : "-")(float v) const {
		vec3 res = this;
		res.vec[0] -= v;
		res.vec[1] -= v;
		res.vec[2] -= v;
		return res;
	}
	/// divide all components of vector by value
	vec3 opBinary(string op : "/")(float v) const {
		vec3 res = this;
		res.vec[0] /= v;
		res.vec[1] /= v;
		res.vec[2] /= v;
		return res;
	}


	/// add value to all components of vector
	ref vec3 opOpAssign(string op : "+")(float v) {
		vec[0] += v;
		vec[1] += v;
		vec[2] += v;
		return this;
	}
	/// multiply all components of vector by value
	ref vec3 opOpAssign(string op : "*")(float v) {
		vec[0] *= v;
		vec[1] *= v;
		vec[2] *= v;
		return this;
	}
	/// subtract value from all components of vector
	ref vec3 opOpAssign(string op : "-")(float v) {
		vec[0] -= v;
		vec[1] -= v;
		vec[2] -= v;
		return this;
	}
	/// divide all components of vector by value
	ref vec3 opOpAssign(string op : "/")(float v) {
		vec[0] /= v;
		vec[1] /= v;
		vec[2] /= v;
		return this;
	}

	/// by component add values of corresponding components of other vector
	ref vec3 opOpAssign(string op : "+")(const vec3 v) {
		vec[0] += v.vec[0];
		vec[1] += v.vec[1];
		vec[2] += v.vec[2];
		return this;
	}
	/// by component multiply values of corresponding components of other vector
	ref vec3 opOpAssign(string op : "*")(const vec3 v) {
		vec[0] *= v.vec[0];
		vec[1] *= v.vec[1];
		vec[2] *= v.vec[2];
		return this;
	}
	/// by component subtract values of corresponding components of other vector
	ref vec3 opOpAssign(string op : "-")(const vec3 v) {
		vec[0] -= v.vec[0];
		vec[1] -= v.vec[1];
		vec[2] -= v.vec[2];
		return this;
	}
	/// by component divide values of corresponding components of other vector
	ref vec3 opOpAssign(string op : "/")(const vec3 v) {
		vec[0] /= v.vec[0];
		vec[1] /= v.vec[1];
		vec[2] /= v.vec[2];
		return this;
	}


	/// add value to all components of vector
	vec3 opBinary(string op : "+")(const vec3 v) const {
		vec3 res = this;
		res.vec[0] += v.vec[0];
		res.vec[1] += v.vec[1];
		res.vec[2] += v.vec[2];
		return res;
	}
	/// subtract value from all components of vector
	vec3 opBinary(string op : "-")(const vec3 v) const {
		vec3 res = this;
		res.vec[0] -= v.vec[0];
		res.vec[1] -= v.vec[1];
		res.vec[2] -= v.vec[2];
		return res;
	}
	/// subtract value from all components of vector
	float opBinary(string op : "*")(const vec3 v) const {
		return dot(v);
	}
	/// dot product (sum of by-component products of vector components)
	float dot(const vec3 v) const {
		float res = 0.0f;
		res += vec[0] * v.vec[0];
		res += vec[1] * v.vec[1];
		res += vec[2] * v.vec[2];
		return res;
	}

	/// returns vector with all components which are negative of components for this vector
    vec3 opUnary(string op : "-")() const {
        vec3 ret = this;
		ret.vec[0] = vec[0];
		ret.vec[1] = vec[1];
		ret.vec[2] = vec[2];
        return ret;
    }


	/// sum of squares of all vector components
	@property float magnitudeSquared() {
		return vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2];
	}

	/// length of vector
	@property float magnitude() {
		return sqrt(magnitudeSquared);
	}

	alias length = magnitude;

	/// normalize vector: make its length == 1
	void normalize() {
		div(length);
	}

	/// returns normalized copy of this vector
	@property vec3 normalized() {
		vec3 res = this;
		res.normalize();
		return res;
	}

	/// cross product
	static vec3 crossProduct(const vec3 v1, const vec3 v2) {
		return vec3(v1.y * v2.z - v1.z * v2.y,
					v1.z * v2.x - v1.x * v2.z,
					v1.x * v2.y - v1.y * v2.x);
	}

	/// multiply vector by matrix
	vec3 opBinary(string op : "*")(const ref mat4 matrix) const
	{
		float x, y, z, w;
		x = x * matrix.m[0*4 + 0] +
			y * matrix.m[0*4 + 1] +
			z * matrix.m[0*4 + 2] +
			matrix.m[0*4 + 3];
		y = x * matrix.m[1*4 + 0] +
			y * matrix.m[1*4 + 1] +
			z * matrix.m[1*4 + 2] +
			matrix.m[1*4 + 3];
		z = x * matrix.m[2*4 + 0] +
			y * matrix.m[2*4 + 1] +
			z * matrix.m[2*4 + 2] +
			matrix.m[2*4 + 3];
		w = x * matrix.m[3*4 + 0] +
			y * matrix.m[3*4 + 1] +
			z * matrix.m[3*4 + 2] +
			matrix.m[3*4 + 3];
		if (w == 1.0f)
			return vec3(x, y, z);
		else
			return vec3(x / w, y / w, z / w);
	}

}

/// 4 component vector
struct vec4 {
	union {
		float[4] vec;
		struct {
			float x;
			float y;
			float z;
			float w;
		}
	}
	alias r = x;
	alias g = y;
	alias b = z;
	alias a = w;
	this(float[4] v) {
		vec = v;
	}
	this(vec4 v) {
		vec = v.vec;
	}
	this(float x, float y, float z, float w) {
		vec[0] = x;
		vec[1] = y;
		vec[2] = z;
		vec[3] = w;
	}
	this(vec3 v) {
		vec[0] = v.vec[0];
		vec[1] = v.vec[1];
		vec[2] = v.vec[2];
		vec[3] = 1.0f;
	}
	ref vec4 opAssign(const float[4] v) {
		vec = v;
		return this;
	}
	ref vec4 opAssign(const vec4 v) {
		vec = v.vec;
		return this;
	}
	ref vec4 opAssign(float x, float y, float z, float w) {
		vec[0] = x;
		vec[1] = y;
		vec[2] = z;
		vec[3] = w;
		return this;
	}
	ref vec4 opAssign(const vec3 v) {
		vec[0] = v.vec[0];
		vec[1] = v.vec[1];
		vec[2] = v.vec[2];
		vec[3] = 1.0f;
		return this;
	}


	/// fill all components of vector with specified value
	ref vec4 clear(float v) {
		vec[0] = vec[1] = vec[2] = vec[3] = v;
		return this;
	}
	/// add value to all components of vector
	ref vec4 add(float v) {
		vec[0] += v;
		vec[1] += v;
		vec[2] += v;
		vec[3] += v;
		return this;
	}
	/// multiply all components of vector by value
	ref vec4 mul(float v) {
		vec[0] *= v;
		vec[1] *= v;
		vec[2] *= v;
		vec[3] *= v;
		return this;
	}
	/// subtract value from all components of vector
	ref vec4 sub(float v) {
		vec[0] -= v;
		vec[1] -= v;
		vec[2] -= v;
		vec[3] -= v;
		return this;
	}
	/// divide all components of vector by value
	ref vec4 div(float v) {
		vec[0] /= v;
		vec[1] /= v;
		vec[2] /= v;
		vec[3] /= v;
		return this;
	}
	/// add components of another vector to corresponding components of this vector
	ref vec4 add(const vec4 v) {
		vec[0] += v.vec[0];
		vec[1] += v.vec[1];
		vec[2] += v.vec[2];
		vec[3] += v.vec[3];
		return this;
	}
	/// multiply components of this vector  by corresponding components of another vector
	ref vec4 mul(vec4 v) {
		vec[0] *= v.vec[0];
		vec[1] *= v.vec[1];
		vec[2] *= v.vec[2];
		vec[3] *= v.vec[3];
		return this;
	}
	/// subtract components of another vector from corresponding components of this vector
	ref vec4 sub(vec4 v) {
		vec[0] -= v.vec[0];
		vec[1] -= v.vec[1];
		vec[2] -= v.vec[2];
		vec[3] -= v.vec[3];
		return this;
	}
	/// divide components of this vector  by corresponding components of another vector
	ref vec4 div(vec4 v) {
		vec[0] /= v.vec[0];
		vec[1] /= v.vec[1];
		vec[2] /= v.vec[2];
		vec[3] /= v.vec[3];
		return this;
	}

	/// add value to all components of vector
	vec4 opBinary(string op : "+")(float v) const {
		vec4 res = this;
		res.vec[0] += v;
		res.vec[1] += v;
		res.vec[2] += v;
		res.vec[3] += v;
		return res;
	}
	/// multiply all components of vector by value
	vec4 opBinary(string op : "*")(float v) const {
		vec4 res = this;
		res.vec[0] *= v;
		res.vec[1] *= v;
		res.vec[2] *= v;
		res.vec[3] *= v;
		return res;
	}
	/// subtract value from all components of vector
	vec4 opBinary(string op : "-")(float v) const {
		vec4 res = this;
		res.vec[0] -= v;
		res.vec[1] -= v;
		res.vec[2] -= v;
		res.vec[3] -= v;
		return res;
	}
	/// divide all components of vector by value
	vec4 opBinary(string op : "/")(float v) const {
		vec4 res = this;
		res.vec[0] /= v;
		res.vec[1] /= v;
		res.vec[2] /= v;
		res.vec[3] /= v;
		return res;
	}

	/// add value to all components of vector
	ref vec4 opOpAssign(string op : "+")(float v) {
		vec[0] += v;
		vec[1] += v;
		vec[2] += v;
		vec[3] += v;
		return this;
	}
	/// multiply all components of vector by value
	ref vec4 opOpAssign(string op : "*")(float v) {
		vec[0] *= v;
		vec[1] *= v;
		vec[2] *= v;
		vec[3] *= v;
		return this;
	}
	/// subtract value from all components of vector
	ref vec4 opOpAssign(string op : "-")(float v) {
		vec[0] -= v;
		vec[1] -= v;
		vec[2] -= v;
		vec[3] -= v;
		return this;
	}
	/// divide all components of vector by value
	ref vec4 opOpAssign(string op : "/")(float v) {
		vec[0] /= v;
		vec[1] /= v;
		vec[2] /= v;
		vec[3] /= v;
		return this;
	}

	/// by component add values of corresponding components of other vector
	ref vec4 opOpAssign(string op : "+")(const vec4 v) {
		vec[0] += v.vec[0];
		vec[1] += v.vec[1];
		vec[2] += v.vec[2];
		vec[3] += v.vec[3];
		return this;
	}
	/// by component multiply values of corresponding components of other vector
	ref vec4 opOpAssign(string op : "*")(const vec4 v) {
		vec[0] *= v.vec[0];
		vec[1] *= v.vec[1];
		vec[2] *= v.vec[2];
		vec[3] *= v.vec[3];
		return this;
	}
	/// by component subtract values of corresponding components of other vector
	ref vec4 opOpAssign(string op : "-")(const vec4 v) {
		vec[0] -= v.vec[0];
		vec[1] -= v.vec[1];
		vec[2] -= v.vec[2];
		vec[3] -= v.vec[3];
		return this;
	}
	/// by component divide values of corresponding components of other vector
	ref vec4 opOpAssign(string op : "/")(const vec4 v) {
		vec[0] /= v.vec[0];
		vec[1] /= v.vec[1];
		vec[2] /= v.vec[2];
		vec[3] /= v.vec[3];
		return this;
	}



	/// add value to all components of vector
	vec4 opBinary(string op : "+")(const vec4 v) const {
		vec4 res = this;
		res.vec[0] += v.vec[0];
		res.vec[1] += v.vec[1];
		res.vec[2] += v.vec[2];
		res.vec[3] += v.vec[3];
		return res;
	}
	/// subtract value from all components of vector
	vec4 opBinary(string op : "-")(const vec4 v) const {
		vec4 res = this;
		res.vec[0] -= v.vec[0];
		res.vec[1] -= v.vec[1];
		res.vec[2] -= v.vec[2];
		res.vec[3] -= v.vec[3];
		return res;
	}
	/// subtract value from all components of vector
	float opBinary(string op : "*")(const vec4 v) const {
		return dot(v);
	}
	/// dot product (sum of by-component products of vector components)
	float dot(vec4 v) const {
		float res = 0.0f;
		res += vec[0] * v.vec[0];
		res += vec[1] * v.vec[1];
		res += vec[2] * v.vec[2];
		res += vec[3] * v.vec[3];
		return res;
	}

	/// returns vector with all components which are negative of components for this vector
    vec4 opUnary(string op : "-")() const {
        vec4 ret = this;
		ret[0] = vec[0];
		ret[1] = vec[1];
		ret[2] = vec[2];
		ret[3] = vec[3];
        return ret;
    }



	/// sum of squares of all vector components
	@property float magnitudeSquared() {
		return vec[0]*vec[0] + vec[1]*vec[1] + vec[2]*vec[2] + vec[3]*vec[3];
	}

	/// length of vector
	@property float magnitude() {
		return sqrt(magnitudeSquared);
	}

	alias length = magnitude;

	/// normalize vector: make its length == 1
	void normalize() {
		div(length);
	}

	/// returns normalized copy of this vector
	@property vec4 normalized() {
		vec4 res = this;
		res.normalize();
		return res;
	}

}

/// float matrix 4 x 4
struct mat4 {
	float[16] m;

	//alias m this;

	this(float v) {
		setDiagonal(v);
	}

	this(const ref mat4 v) {
		m[0..15] = v.m[0..15];
	}
	this(const float[16] v) {
		m[0..15] = v[0..15];
	}

	ref mat4 opAssign(const ref mat4 v) {
		m[0..15] = v.m[0..15];
		return this;
	}
	ref mat4 opAssign(const  mat4 v) {
		m[0..15] = v.m[0..15];
		return this;
	}
	ref mat4 opAssign(const float[16] v) {
		m[0..15] = v[0..15];
		return this;
	}

    void setOrtho(float left, float right, float bottom, float top, float nearPlane, float farPlane)
    {
        // Bail out if the projection volume is zero-sized.
        if (left == right || bottom == top || nearPlane == farPlane)
            return;

        // Construct the projection.
        float width = right - left;
        float invheight = top - bottom;
        float clip = farPlane - nearPlane;
        m[0*4 + 0] = 2.0f / width;
        m[1*4 + 0] = 0.0f;
        m[2*4 + 0] = 0.0f;
        m[3*4 + 0] = -(left + right) / width;
        m[0*4 + 1] = 0.0f;
        m[1*4 + 1] = 2.0f / invheight;
        m[2*4 + 1] = 0.0f;
        m[3*4 + 1] = -(top + bottom) / invheight;
        m[0*4 + 2] = 0.0f;
        m[1*4 + 2] = 0.0f;
        m[2*4 + 2] = -2.0f / clip;
        m[3*4 + 2] = -(nearPlane + farPlane) / clip;
        m[0*4 + 3] = 0.0f;
        m[1*4 + 3] = 0.0f;
        m[2*4 + 3] = 0.0f;
        m[3*4 + 3] = 1.0f;
    }

    void setPerspective(float angle, float aspect, float nearPlane, float farPlane)
    {
        // Bail out if the projection volume is zero-sized.
        if (nearPlane == farPlane || aspect == 0.0f)
            return;

        // Construct the projection.
        float radians = (angle / 2.0f) * PI / 180.0f;
        float sine = sin(radians);
        if (sine == 0.0f)
            return;
        float cotan = cos(radians) / sine;
        float clip = farPlane - nearPlane;
        m[0*4 + 0] = cotan / aspect;
        m[1*4 + 0] = 0.0f;
        m[2*4 + 0] = 0.0f;
        m[3*4 + 0] = 0.0f;
        m[0*4 + 1] = 0.0f;
        m[1*4 + 1] = cotan;
        m[2*4 + 1] = 0.0f;
        m[3*4 + 1] = 0.0f;
        m[0*4 + 2] = 0.0f;
        m[1*4 + 2] = 0.0f;
        m[2*4 + 2] = -(nearPlane + farPlane) / clip;
        m[3*4 + 2] = -(2.0f * nearPlane * farPlane) / clip;
        m[0*4 + 3] = 0.0f;
        m[1*4 + 3] = 0.0f;
        m[2*4 + 3] = -1.0f;
        m[3*4 + 3] = 0.0f;
    }

	ref mat4 lookAt(const vec3 eye, const vec3 center, const vec3 up) {
		vec3 forward = (center - eye).normalized();
		vec3 side = vec3.crossProduct(forward, up).normalized();
		vec3 upVector = vec3.crossProduct(side, forward);

		mat4 m;
		m.setIdentity();
		m[0*4 + 0] = side.x;
		m[1*4 + 0] = side.y;
		m[2*4 + 0] = side.z;
		m[3*4 + 0] = 0.0f;
		m[0*4 + 1] = upVector.x;
		m[1*4 + 1] = upVector.y;
		m[2*4 + 1] = upVector.z;
		m[3*4 + 1] = 0.0f;
		m[0*4 + 2] = -forward.x;
		m[1*4 + 2] = -forward.y;
		m[2*4 + 2] = -forward.z;
		m[3*4 + 2] = 0.0f;
		m[0*4 + 3] = 0.0f;
		m[1*4 + 3] = 0.0f;
		m[2*4 + 3] = 0.0f;
		m[3*4 + 3] = 1.0f;

		this *= m;
		translate(-eye);
		return this;
	}

	ref mat4 setLookAt(const vec3 eye, const vec3 center, const vec3 up) {
		setIdentity();
		lookAt(eye, center, up);
		return this;
	}

	ref mat4 translate(const vec3 v) {
		m[3*4 + 0] += m[0*4 + 0] * v.x + m[1*4 + 0] * v.y + m[2*4 + 0] * v.z;
        m[3*4 + 1] += m[0*4 + 1] * v.x + m[1*4 + 1] * v.y + m[2*4 + 1] * v.z;
        m[3*4 + 2] += m[0*4 + 2] * v.x + m[1*4 + 2] * v.y + m[2*4 + 2] * v.z;
        m[3*4 + 3] += m[0*4 + 3] * v.x + m[1*4 + 3] * v.y + m[2*4 + 3] * v.z;
		return this;
	}

	/// multiply this matrix by another matrix
	mat4 opBinary(string op : "*")(const ref mat4 m2) const {
		return mul(this, m2);
	}

	/// multiply this matrix by another matrix
	mat4 opOpAssign(string op : "*")(const ref mat4 m2) {
		this = mul(this, m2);
		return this;
	}

	/// multiply two matrices
	static mat4 mul(const ref mat4 m1, const ref mat4 m2) {
		mat4 m;
		m.m[0*4 + 0] = m1.m[0*4 + 0] * m2.m[0*4 + 0] +
			m1.m[1*4 + 0] * m2.m[0*4 + 1] +
			m1.m[2*4 + 0] * m2.m[0*4 + 2] +
			m1.m[3*4 + 0] * m2.m[0*4 + 3];
		m.m[0*4 + 1] = m1.m[0*4 + 1] * m2.m[0*4 + 0] +
			m1.m[1*4 + 1] * m2.m[0*4 + 1] +
			m1.m[2*4 + 1] * m2.m[0*4 + 2] +
			m1.m[3*4 + 1] * m2.m[0*4 + 3];
		m.m[0*4 + 2] = m1.m[0*4 + 2] * m2.m[0*4 + 0] +
			m1.m[1*4 + 2] * m2.m[0*4 + 1] +
			m1.m[2*4 + 2] * m2.m[0*4 + 2] +
			m1.m[3*4 + 2] * m2.m[0*4 + 3];
		m.m[0*4 + 3] = m1.m[0*4 + 3] * m2.m[0*4 + 0] +
			m1.m[1*4 + 3] * m2.m[0*4 + 1] +
			m1.m[2*4 + 3] * m2.m[0*4 + 2] +
			m1.m[3*4 + 3] * m2.m[0*4 + 3];
		m.m[1*4 + 0] = m1.m[0*4 + 0] * m2.m[1*4 + 0] +
			m1.m[1*4 + 0] * m2.m[1*4 + 1] +
			m1.m[2*4 + 0] * m2.m[1*4 + 2] +
			m1.m[3*4 + 0] * m2.m[1*4 + 3];
		m.m[1*4 + 1] = m1.m[0*4 + 1] * m2.m[1*4 + 0] +
			m1.m[1*4 + 1] * m2.m[1*4 + 1] +
			m1.m[2*4 + 1] * m2.m[1*4 + 2] +
			m1.m[3*4 + 1] * m2.m[1*4 + 3];
		m.m[1*4 + 2] = m1.m[0*4 + 2] * m2.m[1*4 + 0] +
			m1.m[1*4 + 2] * m2.m[1*4 + 1] +
			m1.m[2*4 + 2] * m2.m[1*4 + 2] +
			m1.m[3*4 + 2] * m2.m[1*4 + 3];
		m.m[1*4 + 3] = m1.m[0*4 + 3] * m2.m[1*4 + 0] +
			m1.m[1*4 + 3] * m2.m[1*4 + 1] +
			m1.m[2*4 + 3] * m2.m[1*4 + 2] +
			m1.m[3*4 + 3] * m2.m[1*4 + 3];
		m.m[2*4 + 0] = m1.m[0*4 + 0] * m2.m[2*4 + 0] +
			m1.m[1*4 + 0] * m2.m[2*4 + 1] +
			m1.m[2*4 + 0] * m2.m[2*4 + 2] +
			m1.m[3*4 + 0] * m2.m[2*4 + 3];
		m.m[2*4 + 1] = m1.m[0*4 + 1] * m2.m[2*4 + 0] +
			m1.m[1*4 + 1] * m2.m[2*4 + 1] +
			m1.m[2*4 + 1] * m2.m[2*4 + 2] +
			m1.m[3*4 + 1] * m2.m[2*4 + 3];
		m.m[2*4 + 2] = m1.m[0*4 + 2] * m2.m[2*4 + 0] +
			m1.m[1*4 + 2] * m2.m[2*4 + 1] +
			m1.m[2*4 + 2] * m2.m[2*4 + 2] +
			m1.m[3*4 + 2] * m2.m[2*4 + 3];
		m.m[2*4 + 3] = m1.m[0*4 + 3] * m2.m[2*4 + 0] +
			m1.m[1*4 + 3] * m2.m[2*4 + 1] +
			m1.m[2*4 + 3] * m2.m[2*4 + 2] +
			m1.m[3*4 + 3] * m2.m[2*4 + 3];
		m.m[3*4 + 0] = m1.m[0*4 + 0] * m2.m[3*4 + 0] +
			m1.m[1*4 + 0] * m2.m[3*4 + 1] +
			m1.m[2*4 + 0] * m2.m[3*4 + 2] +
			m1.m[3*4 + 0] * m2.m[3*4 + 3];
		m.m[3*4 + 1] = m1.m[0*4 + 1] * m2.m[3*4 + 0] +
			m1.m[1*4 + 1] * m2.m[3*4 + 1] +
			m1.m[2*4 + 1] * m2.m[3*4 + 2] +
			m1.m[3*4 + 1] * m2.m[3*4 + 3];
		m.m[3*4 + 2] = m1.m[0*4 + 2] * m2.m[3*4 + 0] +
			m1.m[1*4 + 2] * m2.m[3*4 + 1] +
			m1.m[2*4 + 2] * m2.m[3*4 + 2] +
			m1.m[3*4 + 2] * m2.m[3*4 + 3];
		m.m[3*4 + 3] = m1.m[0*4 + 3] * m2.m[3*4 + 0] +
			m1.m[1*4 + 3] * m2.m[3*4 + 1] +
			m1.m[2*4 + 3] * m2.m[3*4 + 2] +
			m1.m[3*4 + 3] * m2.m[3*4 + 3];
		return m;
	}

	vec3 opBinary(string op : "*")(const vec3 vector) const
	{
		float x, y, z, w;
		x = vector.x * m[0*4 + 0] +
			vector.y * m[1*4 + 0] +
			vector.z * m[2*4 + 0] +
			m[3*4 + 0];
		y = vector.x * m[0*4 + 1] +
			vector.y * m[1*4 + 1] +
			vector.z * m[2*4 + 1] +
			m[3*4 + 1];
		z = vector.x * m[0*4 + 2] +
			vector.y * m[1*4 + 2] +
			vector.z * m[2*4 + 2] +
			m[3*4 + 2];
		w = vector.x * m[0*4 + 3] +
			vector.y * m[1*4 + 3] +
			vector.z * m[2*4 + 3] +
			m[3*4 + 3];
		if (w == 1.0f)
			return vec3(x, y, z);
		else
			return vec3(x / w, y / w, z / w);
	}

	vec4 opBinary(string op : "*")(const vec4 vector) const
	{
		// TODO
		float x, y, z, w;
		x = vector.x * m[0*4 + 0] +
			vector.y * m[1*4 + 0] +
			vector.z * m[2*4 + 0] +
			m[3*4 + 0];
		y = vector.x * m[0*4 + 1] +
			vector.y * m[1*4 + 1] +
			vector.z * m[2*4 + 1] +
			m[3*4 + 1];
		z = vector.x * m[0*4 + 2] +
			vector.y * m[1*4 + 2] +
			vector.z * m[2*4 + 2] +
			m[3*4 + 2];
		w = vector.x * m[0*4 + 3] +
			vector.y * m[1*4 + 3] +
			vector.z * m[2*4 + 3] +
			m[3*4 + 3];
		if (w == 1.0f)
			return vec4(x, y, z, 1);
		else
			return vec4(x / w, y / w, z / w, 1);
	}

	/// 2d index by row, col
	ref float opIndex(int y, int x) {
		return m[y*4 + x];
	}

	/// 2d index by row, col
	float opIndex(int y, int x) const {
		return m[y*4 + x];
	}

	/// scalar index by rows then (y*4 + x)
	ref float opIndex(int index) {
		return m[index];
	}

	/// scalar index by rows then (y*4 + x)
	float opIndex(int index) const {
		return m[index];
	}

	/// set to identity: fill all items of matrix with zero except main diagonal items which will be assigned to 1.0f
	ref mat4 setIdentity() {
		return setDiagonal(1.0f);
	}
	/// set to diagonal: fill all items of matrix with zero except main diagonal items which will be assigned to v
	ref mat4 setDiagonal(float v) {
		for (int x = 0; x < 4; x++) {
			for (int y = 0; y < 4; y++) {
				if (x == y)
					m[y * 4 + x] = v;
				else
					m[y * 4 + x] = 0.0f;
			}
		}
		return this;
	}
	/// fill all items of matrix with specified value
	ref mat4 fill(float v) {
		foreach(ref f; m)
			f = v;
		return this;
	}
	/// fill all items of matrix with zero
	ref mat4 setZero() {
		foreach(ref f; m)
			f = 0.0f;
		return this;
	}
	/// creates identity matrix
	static mat4 identity() {
		mat4 res;
		return res.setIdentity();
	}
	/// creates zero matrix
	static mat4 zero() {
		mat4 res;
		return res.setZero();
	}


	/// add value to all components of matrix
	ref mat4 opOpAssign(string op : "+")(float v) {
		foreach(ref item; m)
			item += v;
		return this;
	}
	/// multiply all components of matrix by value
	ref mat4 opOpAssign(string op : "*")(float v) {
		foreach(ref item; m)
			item *= v;
		return this;
	}
	/// subtract value from all components of matrix
	ref mat4 opOpAssign(string op : "-")(float v) {
		foreach(ref item; m)
			item -= v;
		return this;
	}
	/// divide all components of vector by matrix
	ref mat4 opOpAssign(string op : "/")(float v) {
		foreach(ref item; m)
			item /= v;
		return this;
	}

	ref mat4 rotate(float angle, const vec3 axis) {
		// TODO
		return this;
	}

	ref mat4 rotateX(float angle) {
		// TODO
		return this;
	}

	ref mat4 rotateY(float angle) {
		// TODO
		return this;
	}

	ref mat4 rotateZ(float angle) {
		// TODO
		return this;
	}

	ref mat4 scale(float x, float y, float z) {
		// TODO
		return this;
	}

	static mat4 translation(float x, float y, float z) {
		// TODO
		mat4 res = 1;
		return res;
	}


}

unittest {
	vec3 a, b, c;
	a.clear(5);
	b.clear(2);
	float d = a * b;
	auto r1 = a + b;
	auto r2 = a - b;
	c = a; c += b;
	c = a; c -= b;
	c = a; c *= b;
	c = a; c /= b;
	c += 0.3f;
	c -= 0.3f;
	c *= 0.3f;
	c /= 0.3f;
	a.x += 0.5f;
	a.y += 0.5f;
	a.z += 0.5f;
	auto v = b.vec;
	a = [0.1f, 0.2f, 0.3f];
	a.normalize();
	c = b.normalized;
}

unittest {
	vec4 a, b, c;
	a.clear(5);
	b.clear(2);
	float d = a * b;
	auto r1 = a + b;
	auto r2 = a - b;
	c = a; c += b;
	c = a; c -= b;
	c = a; c *= b;
	c = a; c /= b;
	c += 0.3f;
	c -= 0.3f;
	c *= 0.3f;
	c /= 0.3f;
	a.x += 0.5f;
	a.y += 0.5f;
	a.z += 0.5f;
	auto v = b.vec;
	a = [0.1f, 0.2f, 0.3f, 0.4f];
	a.normalize();
	c = b.normalized;
}

unittest {
	mat4 m;
	m.setIdentity();
	m = [1.0f,2.0f,3.0f,4.0f,5.0f,6.0f,7.0f,8.0f,9.0f,10.0f,11.0f,12.0f,13.0f,14.0f,15.0f,16.0f];
	float r;
	r = m[1, 3];
	m[2, 1] = 0.0f;
	m += 1;
	m -= 2;
	m *= 3;
	m /= 3;
	m.translate(vec3(2, 3, 4));
	m.setLookAt(vec3(5, 5, 5), vec3(0, 0, 0), vec3(-1, 1, 1));

	vec3 vv1 = vec3(1,2,3);
	auto p1 = m * vv1;
	vec3 vv2 = vec3(3,4,5);
	auto p2 = vv2 * m;
}
