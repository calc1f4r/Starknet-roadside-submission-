#[starknet::interface]
trait ISimpleCounter<T> {
    fn get_counter(self: @T) -> u32;
    fn increase_counter(ref self: T);
}

#[starknet::interface]
trait IkillSwitchWrapper<TContractState> {
    fn is_active(self: @TContractState) -> bool;
}


#[starknet::contract]
pub mod counter_contract {
    use openzeppelin::access::ownable::OwnableComponent;
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    use core::starknet::{ContractAddress, syscalls, SyscallResultTrait, get_caller_address};
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl InternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        counter: u32,
        kill_switch: ContractAddress,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
    }
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CounterIncrease: CounterIncrease,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }
    #[derive(Drop, starknet::Event)]
    struct CounterIncrease {
        #[key]
        counter: u32,
    }

    #[constructor]
    fn constructor(ref self: ContractState, counter: u32, kill_switch: ContractAddress, initial_owner: ContractAddress) {
        self.counter.write(counter);
        self.kill_switch.write(kill_switch);
         self.ownable.initializer(initial_owner);

    }
    #[abi(embed_v0)]
    impl SimpleCounter of super::ISimpleCounter<ContractState> {
        fn get_counter(self: @ContractState) -> u32 {
            return self.counter.read();
        }
        fn increase_counter(ref self: ContractState) {
            self.ownable.assert_only_owner();

            let kill_switch_address: ContractAddress = self.kill_switch.read();
            let mut call_data: Array<felt252> = array![];

            let mut res = syscalls::call_contract_syscall(
                kill_switch_address, selector!("is_active"), call_data.span()
            )
                .unwrap_syscall();

            // Call the is_active method
            // let is_active = kill_switch_dispatcher.is_active();
            let is_active: bool = Serde::<bool>::deserialize(ref res).unwrap();
            assert(is_active, 0);

            let counter = self.counter.read();
            self.counter.write(counter + 1);
            self.emit(Event::CounterIncrease(CounterIncrease { counter: counter + 1 }));
        }
    }
}
