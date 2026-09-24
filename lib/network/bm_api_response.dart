/// BMApiResponse - networkresponseclass
/// purposescope: allhasnetworkrequest of unifiedresponsestructure
/// includesstatecode code、responsedata data、message message
class BMApiResponse<T> {
 /// statecode (int type, 0 meanssuccess)
 final int? code;

 /// responsedatabody (type T type)
 final T? data;

 /// responsemessage (String type)
 final String? message;

 BMApiResponse({this.code, this.data, this.message});

 /// whetherrequest success (bool type, code == 0 when true)
 bool get isSuccess => code == 0;
}