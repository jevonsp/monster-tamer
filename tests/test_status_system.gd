extends GutTest


class _ProbeAction extends Action:
	var ran: bool = false
	var ran_count: int = 0

	func _trigger_impl(_ctx: ActionContext) -> Flow:
		ran = true
		ran_count += 1
		return Flow.NEXT


class _SetBlockProbe extends Action:
	func _trigger_impl(ctx: ActionContext) -> Flow:
		ctx.data["block_action"] = true
		return Flow.STOP


class _SetSubstituteProbe extends Action:
	var sub: ActionList = null

	func _trigger_impl(ctx: ActionContext) -> Flow:
		ctx.data["substitute_action_list"] = sub
		return Flow.STOP


class _SetBothProbe extends Action:
	var sub: ActionList = null

	func _trigger_impl(ctx: ActionContext) -> Flow:
		ctx.data["substitute_action_list"] = sub
		ctx.data["block_action"] = true
		return Flow.STOP


func _make_monster(p_attack: int = 50, p_max_hp: int = 80) -> Monster:
	var m := Monster.new()
	m.name = "TestMon"
	m.attack = p_attack
	m.special_attack = p_attack
	m.defense = 50
	m.special_defense = 50
	m.speed = 50
	m.max_hitpoints = p_max_hp
	m.current_hitpoints = p_max_hp
	m.level = 10
	return m


func _make_status(
		p_id: StringName,
		p_slot: StatusData.StatusSlot = StatusData.StatusSlot.PRIMARY,
		p_duration: int = -1,
		p_policy: StatusData.StackPolicy = StatusData.StackPolicy.REJECT,
) -> StatusData:
	var s := StatusData.new()
	s.id = p_id
	s.name = String(p_id)
	s.slot = p_slot
	s.default_duration = p_duration
	s.stack_policy = p_policy
	return s


func _wrap_in_list(action: Action) -> ActionList:
	var list := ActionList.new()
	list.actions = [action]
	return list


func _make_chassis() -> BattleChassis:
	var c := BattleChassis.new()
	c.in_battle = true
	return c


func _make_choice(actor: Monster, target: Monster, action_list: ActionList) -> Choice:
	var choice := Choice.new()
	# Use SWITCH so _resolve_action_list returns the raw ActionList (the MOVE
	# branch unwraps via Move.action_list which we don't construct here).
	choice.type = Choice.Type.SWITCH
	choice.actor = actor
	choice.targets = [target]
	choice.action_or_list = action_list
	return choice


# --- Monster status API ---

func test_add_status_primary_slot() -> void:
	var m := _make_monster()
	var data := _make_status(&"poison")
	var inst := StatusInstance.from_data(data)
	assert_true(m.add_status(inst))
	assert_true(m.has_status(&"poison"))
	assert_eq(m.primary_status, inst)


func test_add_status_reject_collision() -> void:
	var m := _make_monster()
	var data := _make_status(&"poison", StatusData.StatusSlot.PRIMARY, -1, StatusData.StackPolicy.REJECT)
	assert_true(m.add_status(StatusInstance.from_data(data)))
	var second := StatusInstance.from_data(data)
	assert_false(m.add_status(second))
	assert_ne(m.primary_status, second)


func test_add_status_replace_collision() -> void:
	var m := _make_monster()
	var data := _make_status(
		&"poison", StatusData.StatusSlot.PRIMARY, 3, StatusData.StackPolicy.REPLACE,
	)
	assert_true(m.add_status(StatusInstance.from_data(data)))
	var second := StatusInstance.from_data(data)
	assert_true(m.add_status(second))
	assert_eq(m.primary_status, second)


func test_add_status_refresh_collision() -> void:
	var m := _make_monster()
	var data := _make_status(
		&"poison", StatusData.StatusSlot.PRIMARY, 3, StatusData.StackPolicy.REFRESH,
	)
	var first := StatusInstance.from_data(data)
	assert_true(m.add_status(first))
	first.turns_remaining = 1
	assert_true(m.add_status(StatusInstance.from_data(data)))
	assert_eq(m.primary_status, first)
	assert_eq(first.turns_remaining, 3)
	assert_eq(first.stacks, 2)


func test_remove_status() -> void:
	var m := _make_monster()
	m.add_status(StatusInstance.from_data(_make_status(&"burn")))
	assert_true(m.remove_status(&"burn"))
	assert_false(m.has_status(&"burn"))


func test_get_statuses_with_hook() -> void:
	var m := _make_monster()
	var data := _make_status(&"burn")
	data.on_turn_end = ActionList.new()
	m.add_status(StatusInstance.from_data(data))

	var with_end := m.get_statuses_with_hook(&"on_turn_end")
	assert_eq(with_end.size(), 1)

	var with_start := m.get_statuses_with_hook(&"on_turn_start")
	assert_eq(with_start.size(), 0)


# --- Stat-modifier pipeline ---

func test_get_effective_stat_no_status() -> void:
	var m := _make_monster(100)
	assert_eq(m.get_effective_stat(Monster.Stat.ATTACK), 100.0)


func test_burn_passive_halves_attack() -> void:
	var m := _make_monster(100)
	var burn := _make_status(&"burn")
	burn.stat_multipliers = { Monster.Stat.ATTACK: 0.5 }
	m.add_status(StatusInstance.from_data(burn))
	assert_eq(m.get_effective_stat(Monster.Stat.ATTACK), 50.0)
	assert_eq(m.get_effective_stat(Monster.Stat.SPECIAL_ATTACK), 100.0)


func test_burn_only_affects_physical_damage() -> void:
	var attacker := _make_monster(100)
	var burn := _make_status(&"burn")
	burn.stat_multipliers = { Monster.Stat.ATTACK: 0.5 }
	attacker.add_status(StatusInstance.from_data(burn))

	var target := _make_monster(50, 200)

	var physical := DamageAction.new()
	physical.base_power = 40
	physical.category = DamageAction.DamageCategory.PHYSICAL

	var special := DamageAction.new()
	special.base_power = 40
	special.category = DamageAction.DamageCategory.SPECIAL

	var ctx_phys := ActionContext.new(null, _make_choice(attacker, target, ActionList.new()), BattlePresenter.new())
	target.current_hitpoints = target.max_hitpoints
	physical._trigger_impl(ctx_phys)
	var phys_dmg: int = ctx_phys.data["last_hp_change"]["damage"]

	var ctx_spec := ActionContext.new(null, _make_choice(attacker, target, ActionList.new()), BattlePresenter.new())
	target.current_hitpoints = target.max_hitpoints
	special._trigger_impl(ctx_spec)
	var spec_dmg: int = ctx_spec.data["last_hp_change"]["damage"]

	assert_eq(phys_dmg, 20)
	assert_eq(spec_dmg, 40)


# --- Burn tick (DamageAction self + fractional) ---

func test_burn_tick_damages_self_by_fraction() -> void:
	var m := _make_monster(50, 80)
	var ctx := ActionContext.new(null, _make_choice(m, m, ActionList.new()), BattlePresenter.new())

	var damage := DamageAction.new()
	damage.target_self = true
	damage.fraction_of_max_hp = 0.125
	damage._trigger_impl(ctx)

	assert_eq(m.current_hitpoints, 70)
	assert_eq(int(ctx.data["last_hp_change"]["damage"]), 10)


# --- Phase hook resolver semantics ---

func test_block_action_skips_main_action_list() -> void:
	var chassis := _make_chassis()
	var attacker := _make_monster()
	var target := _make_monster()

	var probe := _ProbeAction.new()
	var move_list := _wrap_in_list(probe)

	var blocker_action := _SetBlockProbe.new()
	var blocker := _make_status(&"sleep")
	blocker.on_potential_block = _wrap_in_list(blocker_action)
	attacker.add_status(StatusInstance.from_data(blocker))

	var choice := _make_choice(attacker, target, move_list)
	chassis.turn_queue = [choice]

	await chassis.resolve_turn(BattlePresenter.new())

	assert_false(probe.ran, "Original move ran but block_action was set")


func test_substitute_action_list_runs_in_place_of_original() -> void:
	var chassis := _make_chassis()
	var attacker := _make_monster()
	var target := _make_monster()

	var original_probe := _ProbeAction.new()
	var move_list := _wrap_in_list(original_probe)

	var sub_probe := _ProbeAction.new()
	var sub_list := _wrap_in_list(sub_probe)

	var setter := _SetSubstituteProbe.new()
	setter.sub = sub_list
	var conf := _make_status(&"confusion")
	conf.on_potential_block = _wrap_in_list(setter)
	attacker.add_status(StatusInstance.from_data(conf))

	var choice := _make_choice(attacker, target, move_list)
	chassis.turn_queue = [choice]

	await chassis.resolve_turn(BattlePresenter.new())

	assert_false(original_probe.ran, "Original move ran when substitute was set")
	assert_true(sub_probe.ran, "Substitute ActionList did not run")


func test_block_action_takes_precedence_over_substitute() -> void:
	var chassis := _make_chassis()
	var attacker := _make_monster()
	var target := _make_monster()

	var original_probe := _ProbeAction.new()
	var sub_probe := _ProbeAction.new()
	var move_list := _wrap_in_list(original_probe)
	var sub_list := _wrap_in_list(sub_probe)

	var setter := _SetBothProbe.new()
	setter.sub = sub_list
	var status := _make_status(&"weird")
	status.on_potential_block = _wrap_in_list(setter)
	attacker.add_status(StatusInstance.from_data(status))

	var choice := _make_choice(attacker, target, move_list)
	chassis.turn_queue = [choice]

	await chassis.resolve_turn(BattlePresenter.new())

	assert_false(original_probe.ran, "Original move ran despite block_action being set")
	assert_false(sub_probe.ran, "Substitute ran despite block_action being set")


# --- Duration / TickStatusesAction ---

func test_tick_decrements_and_expires_status() -> void:
	var m := _make_monster()
	var data := _make_status(&"poison", StatusData.StatusSlot.TERTIARY, 2, StatusData.StackPolicy.REJECT)
	var expire_probe := _ProbeAction.new()
	data.on_expire = _wrap_in_list(expire_probe)
	var inst := StatusInstance.from_data(data, m)
	m.add_status(inst)

	var ctx := ActionContext.new(null, _make_choice(m, m, ActionList.new()), BattlePresenter.new())
	ctx.data["acting_status"] = inst

	var tick := TickStatusesAction.new()
	await tick._trigger_impl(ctx)
	assert_eq(inst.turns_remaining, 1)
	assert_true(m.has_status(&"poison"))
	assert_eq(expire_probe.ran_count, 0)

	await tick._trigger_impl(ctx)
	assert_eq(inst.turns_remaining, 0)
	assert_false(m.has_status(&"poison"))
	assert_eq(expire_probe.ran_count, 1)
