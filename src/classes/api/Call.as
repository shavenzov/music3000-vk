package classes.api
{
	import flash.net.Responder;
	
	public class Call
	{
		public var func : String;
		public var callback : Function;
		public var params : Array;
		
		public function Call( func : String, callback : Function, params : Array )
		{
			this.func = func;
			this.callback = callback;
			this.params = params;
		}
		
		public function getData( responder : Responder ) : Array
		{
			var data : Array = [ func, responder ];
			
			if ( params && params.length > 0 )
			{
				for each ( var param : * in params )
				{
					data.push( param );
				}	
			}
			
			return data;
		}
	}
}