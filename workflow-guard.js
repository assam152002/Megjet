(() => {
  "use strict";

  const allowedTransitions = {
    pending: new Set(["confirmed", "cancelled"]),
    confirmed: new Set(["preparing", "cancelled"]),
    preparing: new Set(["ready_for_pickup", "cancelled"]),
    ready_for_pickup: new Set(["out_for_delivery", "cancelled"]),
    out_for_delivery: new Set(["delivered", "cancelled"]),
    delivered: new Set(),
    cancelled: new Set()
  };

  function currentAdminOrder(orderId) {
    return (window.adminOrdersCache || []).find(order => String(order.id) === String(orderId));
  }

  function removeDeliveryBypasses() {
    document.querySelectorAll('#riderOrders button[onclick*="riderMarkDelivered"]').forEach(button => {
      const actions = button.closest(".rider-order-actions");
      button.remove();
      if (actions && !actions.querySelector("button") && !actions.querySelector("a")) actions.remove();
    });
  }

  const originalQuickOrderStatus = window.quickOrderStatus;
  if (typeof originalQuickOrderStatus === "function") {
    window.quickOrderStatus = async function(orderId, nextStatus) {
      const order = currentAdminOrder(orderId);
      if (!order) return originalQuickOrderStatus(orderId, nextStatus);

      const current = typeof window.normalizedStatus === "function"
        ? window.normalizedStatus(order.status)
        : String(order.status || "pending").toLowerCase();
      const next = String(nextStatus || "").toLowerCase();

      if (!allowedTransitions[current]?.has(next)) {
        alert("This change is blocked. Order #" +
          (typeof window.displayOrderId === "function" ? window.displayOrderId(orderId) : orderId) +
          " must follow the normal order stages.");
        return;
      }

      if (next === "out_for_delivery") {
        const assigned = window.adminOrderRiderMap?.[String(orderId)];
        if (!assigned) {
          alert("Assign a rider before sending this order out for delivery.");
          return;
        }
      }

      if (next === "delivered") {
        alert("Delivery must be completed by the assigned rider using the customer's 4-digit PIN.");
        return;
      }

      return originalQuickOrderStatus(orderId, next);
    };
  }

  const originalChangeAdminOrderStatus = window.changeAdminOrderStatus;
  if (typeof originalChangeAdminOrderStatus === "function") {
    window.changeAdminOrderStatus = async function(orderId, nextStatus) {
      const order = currentAdminOrder(orderId);
      if (!order) return originalChangeAdminOrderStatus(orderId, nextStatus);

      const current = typeof window.normalizedStatus === "function"
        ? window.normalizedStatus(order.status)
        : String(order.status || "pending").toLowerCase();
      const next = String(nextStatus || "").toLowerCase();

      if (!allowedTransitions[current]?.has(next)) {
        alert("Status changes must follow Pending → Confirmed → Preparing → Ready for Pickup → Out for Delivery → Delivered.");
        if (typeof window.renderAdminOrders === "function") window.renderAdminOrders();
        return;
      }

      if (next === "out_for_delivery" && !window.adminOrderRiderMap?.[String(orderId)]) {
        alert("Assign a rider before sending this order out for delivery.");
        if (typeof window.renderAdminOrders === "function") window.renderAdminOrders();
        return;
      }

      if (next === "delivered") {
        alert("The assigned rider must verify the customer's 4-digit PIN to complete delivery.");
        if (typeof window.renderAdminOrders === "function") window.renderAdminOrders();
        return;
      }

      return originalChangeAdminOrderStatus(orderId, next);
    };
  }

  window.riderMarkDelivered = function() {
    alert("Use “Verify PIN & Mark Delivered” and enter the customer's 4-digit delivery PIN.");
  };

  const observer = new MutationObserver(removeDeliveryBypasses);
  const riderOrders = document.getElementById("riderOrders");
  if (riderOrders) observer.observe(riderOrders, { childList: true, subtree: true });
  removeDeliveryBypasses();
})();