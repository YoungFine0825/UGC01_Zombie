---@class BP_Shield_C:AActor
---@field ParticleSystem UParticleSystemComponent
---@field DefaultSceneRoot USceneComponent
---@field BlockParticle UParticleSystem
---@field BlockDurability int32
--Edit Below--

local BP_Shield = {
	---@type AActor
	ShieldOwner = nil,
	BlockedActors = {}
}

function BP_Shield:ReceiveBeginPlay()
	print_dev("BP_Shield:ReceiveBeginPlay()")
    BP_Shield.SuperClass.ReceiveBeginPlay(self)

	if not self:HasAuthority() then
		return
	end

	self.ShieldOwner = self:GetOwner()
	self:LuaInit()
end

function BP_Shield:ReceiveEndPlay()
	self.StaticMesh.OnComponentBeginOverlap:Remove(self.StaticMesh_OnComponentBeginOverlap, self);

	if self:HasAuthority() then
		GMP.Unbind("UGC.Weapon.BulletHit", self)
	end
end

-- [Editor Generated Lua] function define Begin:
function BP_Shield:LuaInit()
	if self.bInitDoOnce then
		return;
	end

	self.bInitDoOnce = true;
	self.StaticMesh.OnComponentBeginOverlap:Add(self.StaticMesh_OnComponentBeginOverlap, self);
	
	GMP.Unbind("UGC.Weapon.BulletHit", self)
    GMP.GlobalMessage.BindUObject(self, "UGC.Weapon.BulletHit", self, self.OnBulletHit)

	print_dev("BP_Shield:LuaInit Done")
end

function BP_Shield:Multicast_ReceiveBlock(Actor)
	if UE.IsValid(Actor) then
		GameplayStatics.SpawnEmitterAtLocation(self,
		self.BlockParticle,
		Actor:K2_GetActorLocation(),
		Actor:K2_GetActorRotation(),
		Vector.New(1,1,1),
		true)
	end
end

function BP_Shield:Rpc_DestroyShield()
	if UE.IsValid(self) then
		self:K2_DestroyActor()
		self:SetLifeSpan(0.1)
		print_dev("BP_Shield:Rpc_DestroyShield Destroy Shield by Bullet after durability <= 0, " .. tostring(self))
	end
end

function BP_Shield:LuaInnerFunction_OnComponentBeginOverlap(OtherActor)
	if not self:HasAuthority() then
		return
	end

	--local Class = UE.LoadClass("/Script/ShadowTrackerExtra.UniversalProjectileBase");
	if OtherActor and UE.IsA(OtherActor, self.UniversalProjectileBaseClass) then
	
		---@param OtherActor UniversalProjectileBase
		local OtherActorInstigator = OtherActor:GetInstigator()
		print_dev("BP_Shield:LuaInnerFunction_OnComponentBeginOverlap"..tostring(OtherActorInstigator))

		if OtherActorInstigator ~=nil then
			local Relation = self.ShieldOwner:GetGeneralCampRelationWithActor(OtherActorInstigator)
			print_dev("BP_Shield:LuaInnerFunction_OnComponentBeginOverlap Relation = "..tostring(Relation))

			-- 阻挡非友方飞行道具 
			if Relation == ECampRelation.Enemy or Relation == ECampRelation.Neutral then
				print_dev("BP_Shield:LuaInnerFunction_OnComponentBeginOverlap Block Projectile")

				-- 通知各客户端生成特效，服务器销毁飞行道具
				UnrealNetwork.CallUnrealRPC_Multicast(self ,"Multicast_ReceiveBlock",OtherActor)
				OtherActor:K2_DestroyActor()

				-- 更新护盾耐久度
				self.BlockDurability = self.BlockDurability - 1
				if self.BlockDurability <= 0 then
					-- self:K2_DestroyActor()
					self:SetLifeSpan(0.1)
					print_dev("BP_Shield:StaticMesh_OnComponentHit Destroy Shield by Projectile after durability <= 0, " .. tostring(self))
				end
			end
		end
		
	end
end

function BP_Shield:StaticMesh_OnComponentBeginOverlap(OverlappedComponent, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
	self:LuaInnerFunction_OnComponentBeginOverlap(OtherActor)
	return nil;
end

function BP_Shield:OnBulletHit(ASTExtraShootWeapon, HitData)
	if HitData == nil then
		return
	end
	
	local HitActor = HitData.Actor:Get()
	if not UE.IsValid(HitActor) then
		print_dev("BP_Shield:OnBulletHit HitActor is nil")
		return;
	end
	
	if HitActor ~= self then
		return;
	end

	self.BlockDurability = self.BlockDurability - 1
	if self.BlockDurability <= 0 then
		self:K2_DestroyActor()
		self:SetLifeSpan(0.1)
		print_dev("BP_Shield:StaticMesh_OnComponentHit Destroy Shield by Projectile after durability <= 0")
	end
	print_dev("BP_Shield:OnBulletHit " .. tostring(self.BlockDurability))
end

return BP_Shield