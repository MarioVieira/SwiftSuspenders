package org.swiftsuspenders.interfaces
{
	import org.swiftsuspenders.Injector;
	
	public interface IInjectorDependant
	{
		function init(injector:Injector):void;
	}
}