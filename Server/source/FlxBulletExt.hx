package ;
import networkobj.NEmitter;
import ext.FlxBulletExtBase;
import ext.FlxWeaponExt;

/**
 * ...
 * @author Ohmnivore
 */
class FlxBulletExt extends FlxBulletExtBase
{
	override public function fireEmitter(W:FlxWeaponExt):Void 
	{
		super.fireEmitter(W);
		
		if (emitter == null)
		{
			emitter = NEmitter.cloneFromEmitter(NEmitter.emitters.get(W.template.TRAIL_EMITTER), 0, 0);
			Reg.state.emitters.add(emitter);
			emitter.makeParticles(Assets.images.get(W.template.TRAIL_EMITTER_GRAPHIC), 40);
			emitter.autoDestroy = false;
		}
		emitter.start(false, emitter.life.min, emitter.frequency, 40, emitter.life.max - emitter.life.min);
	}
}