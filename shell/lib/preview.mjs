export function idle() {
    return { active: false, original: "", applied: "", pending: "" }
}

export function begin(id) {
    return { active: true, original: id, applied: id, pending: "" }
}

export function settle(state, id) {
    return state.active ? Object.assign({}, state, { pending: id }) : state
}

export function fire(state) {
    if (!state.active || state.pending === "" || state.pending === state.applied)
        return { state: Object.assign({}, state, { pending: "" }), apply: "" }
    return { state: Object.assign({}, state, { applied: state.pending, pending: "" }), apply: state.pending }
}

export function commit(state, front) {
    if (!state.active)
        return { state: idle(), apply: "" }
    return { state: idle(), apply: front !== "" && front !== state.applied ? front : "" }
}

export function cancel(state) {
    if (!state.active)
        return { state: idle(), apply: "" }
    return { state: idle(), apply: state.original !== "" && state.applied !== state.original ? state.original : "" }
}
