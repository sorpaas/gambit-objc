#include "objc-call.h"
#include "objc-type.h"
#include "objc-resource.h"
#include <string.h>
#include <stdlib.h>

static struct objc_type *call_parameter_type(struct objc_call *call, int n)
{
        char *signature, *scanp;
        
        signature = scanp = method_copyArgumentType(call->method, n);
        if (!signature)
                return NULL;

        struct objc_type *type = parse_next_type(call, &scanp);
        free(signature);
        return type;
}

static ___SCMOBJ call_find_parameter_types(struct objc_call *call)
{
        int i;
        for (i = 0; i < call->parameter_count; ++i)
                if (!(call->parameter_types[i] = call_parameter_type(call, i)))
                        return ___FIX(___UNKNOWN_ERR);
        return ___FIX(___NO_ERR);
}

static ___SCMOBJ call_parse_parameters(struct objc_call *call, ___SCMOBJ args)
{
	call->parameter_values[0] = allocate_for_call(call, sizeof(id));
	*(id*)call->parameter_values[0] = call->target;

	call->parameter_values[1] = allocate_for_call(call, sizeof(SEL));
	*(SEL*)call->parameter_values[1] = call->selector;

        int i;
        for (i = 2; ___PAIRP(args); args = ___CDR(args), ++i) {
		___SCMOBJ arg = ___CAR(args);
		___SCMOBJ err = ___FIX(___NO_ERR);

		call->parameter_values[i] = allocate_for_call(call, call->parameter_types[i]->call_type->size);
		if (!call->parameter_values[i])
			return ___FIX(___UNKNOWN_ERR);

		err = call->parameter_types[i]->make_parameter (
			call->parameter_types[i],
			call->parameter_values[i],
			arg
			);
		if (err != ___FIX(___NO_ERR))
			return err;
	}
	return ___FIX(___NO_ERR);
}

static struct objc_type *call_return_type(struct objc_call *call)
{
        char *scanp = (char*)method_getTypeEncoding(call->method);
        return parse_next_type(call, &scanp);
}

static ___SCMOBJ call_invoke(struct objc_call *call, ___SCMOBJ *result)
{
	ffi_cif cif;
	struct objc_type *return_type = call_return_type(call);
	void *return_value = allocate_for_call(call, return_type->call_type->size);
	ffi_type **arg_types = allocate_for_call(call, sizeof(ffi_type*) * call->parameter_count);
	int i;

	for (i = 0; i < call->parameter_count; ++i)
                arg_types[i] = call->parameter_types[i]->call_type;

	if (ffi_prep_cif(&cif, FFI_DEFAULT_ABI, call->parameter_count,
			 return_type->call_type, arg_types) != FFI_OK)
		return ___FIX(___UNKNOWN_ERR);

	ffi_call(&cif, (void (*)())call->imp, return_value, call->parameter_values);

	return return_type->convert_return (return_type, return_value, result);
}

static void release_call_parameters(struct objc_call *call)
{
	int i;
	for (i = 0; i < call->parameter_count; ++i) {
		if (call->parameter_types[i]->release_parameter)
			call->parameter_types[i]->release_parameter (
				call->parameter_types[i],
				call->parameter_values[i]
				);
	}
}

static void call_clean_up(struct objc_call *call)
{
	release_call_parameters(call);
	free_resources(call);
}

static ___SCMOBJ call_method(id target, SEL selector, ___SCMOBJ *result, ___SCMOBJ args)
{
	struct objc_call call;
	Class class;
	___SCMOBJ err = ___FIX(___NO_ERR);

	memset(&call, 0, sizeof(call));
	call.target = target;
	call.selector = selector;
	class = (Class)object_getClass(call.target);
	call.method = class_getInstanceMethod(class, call.selector);
	if (!call.method)
		return ___FIX(___UNIMPL_ERR);
	call.imp = method_getImplementation(call.method);
        call.parameter_count = method_getNumberOfArguments(call.method);

        err = call_find_parameter_types(&call);
        if (err != ___FIX(___NO_ERR))
                goto done;

	err = call_parse_parameters(&call, args);
	if (err != ___FIX(___NO_ERR))
                goto done;

	err = call_invoke(&call, result);
done:
	call_clean_up(&call);
	return err;
}

