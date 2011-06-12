package org.swiftsuspenders.injectionpoints
{
	import org.swiftsuspenders.Injector;
	import org.swiftsuspenders.interfaces.IInjectorDependant;
	
	
	public class InjectorProvider extends Injector
	{
		public function InjectorProvider(xmlConfig:XML=null)
		{
			super(xmlConfig);
		}
		
		override public function getInstance(clazz:Class, named:String=''):*
		{
			var entity:* = super.getInstance(clazz, named);
			if(entity is Object && entity is IInjectorDependant) 
				IInjectorDependant(entity).init(this);
			
			return entity;
		}
	}
}