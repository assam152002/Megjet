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
    return (typeof adminOrdersCache !== "undefined" ? adminOrdersCache : []).find(order => String(order.id) === String(orderId));
  }

  const originalSaveOrderStatus = window.saveOrderStatus;
  if (typeof originalSaveOrderStatus === "function") {
    window.saveOrderStatus = async function(orderId, nextStatus) {
      const order = currentAdminOrder(orderId);
      if (!order) {
        alert("Refresh Admin orders before changing this order's status.");
        return;
      }
      const current = typeof window.normalizedStatus === "function"
        ? window.normalizedStatus(order.status)
        : String(order.status || "pending").toLowerCase();
      const next = String(nextStatus || "").toLowerCase();
      if (!allowedTransitions[current]?.has(next)) {
        alert("Status changes must follow Pending → Confirmed → Preparing → Ready for Pickup → Out for Delivery → Delivered.");
        return;
      }
      if (next === "delivered") {
        alert("The assigned rider must verify the customer's 4-digit PIN to complete delivery.");
        return;
      }
      if (next === "out_for_delivery" && !(typeof adminOrderRiderMap !== "undefined" && adminOrderRiderMap[String(orderId)])) {
        alert("Assign a rider before sending this order out for delivery.");
        return;
      }
      return originalSaveOrderStatus(orderId, nextStatus);
    };
  }
  window.changeAdminOrderStatus = function(orderId, nextStatus) {
    return window.saveOrderStatus(orderId, nextStatus);
  };

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

      if (next === "out_for_delivery" && !(typeof adminOrderRiderMap !== "undefined" && adminOrderRiderMap[String(orderId)])) {
        alert("Assign a rider before sending this order out for delivery.");
        return;
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

      if (next === "out_for_delivery" && !(typeof adminOrderRiderMap !== "undefined" && adminOrderRiderMap[String(orderId)])) {
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

  function checkoutMessage(text) {
    const message = document.getElementById("orderMessage");
    if (message) {
      message.textContent = text;
      message.setAttribute("role", "alert");
    }
  }

  function configurePayments() {
    const payment = document.getElementById("paymentMethod");
    if (!payment) return;
    const card = Array.from(payment.options).find(option => option.value === "Credit / Debit Card");
    if (card) {
      card.disabled = true;
      card.textContent = "Credit / Debit Card — Coming Soon";
    }
    if (payment.value === "Credit / Debit Card") payment.value = "Cash on Delivery";
  }

  function checkoutFingerprint(name, phone, address) {
    const items = (window.cart || []).map(item => [
      String(item.id || ""),
      Math.max(1, Number(item.quantity || 1))
    ]);
    return JSON.stringify([name.toLowerCase(), phone, address.toLowerCase(), items]);
  }

  function protectCheckout() {
    const button = document.getElementById("placeOrder");
    if (!button || button.dataset.megjetProtected === "true" || typeof button.onclick !== "function") return;

    const originalPlaceOrder = button.onclick;
    let submitting = false;
    button.dataset.megjetProtected = "true";
    button.onclick = async function(event) {
      if (submitting) return;
      const name = document.getElementById("customerName")?.value.trim() || "";
      const rawPhone = document.getElementById("phone")?.value.trim() || "";
      const phone = rawPhone.replace(/[^0-9]/g, "");
      const address = document.getElementById("address")?.value.trim() || "";
      const items = window.cart || [];

      if (name.length < 2) {
        checkoutMessage("Please enter your full name.");
        document.getElementById("customerName")?.focus();
        return;
      }
      if (phone.length < 8 || phone.length > 15) {
        checkoutMessage("Please enter a valid phone number with 8 to 15 digits.");
        document.getElementById("phone")?.focus();
        return;
      }
      if (address.length < 8) {
        checkoutMessage("Please enter a complete delivery address in Gazimagusa.");
        document.getElementById("address")?.focus();
        return;
      }
      if (!items.length || items.some(item => !item.id || Number(item.quantity || 0) < 1 || Number(item.quantity || 0) > 50)) {
        checkoutMessage("Your cart contains an invalid item. Please refresh the menu and try again.");
        return;
      }

      if (document.getElementById("paymentMethod")?.value !== "Cash on Delivery") {
        checkoutMessage("Card payment is coming soon. Please choose Cash on Delivery.");
        return;
      }
      const fingerprint = checkoutFingerprint(name, phone, address);
      const previous = sessionStorage.getItem("megjet_checkout_fingerprint");
      const previousAt = Number(sessionStorage.getItem("megjet_checkout_time") || 0);
      if (previous === fingerprint && Date.now() - previousAt < 60000) {
        checkoutMessage("This order was already submitted. Please check My Orders before trying again.");
        return;
      }

      const oldOrderId = String(window.trackedOrderId || localStorage.getItem("megjet_last_order_id") || "");
      sessionStorage.setItem("megjet_checkout_fingerprint", fingerprint);
      sessionStorage.setItem("megjet_checkout_time", String(Date.now()));

      submitting = true;
      button.disabled = true;
      try {
        await originalPlaceOrder.call(this, event);
        const newOrderId = String(window.trackedOrderId || localStorage.getItem("megjet_last_order_id") || "");
        if (!newOrderId || newOrderId === oldOrderId) {
          sessionStorage.removeItem("megjet_checkout_fingerprint");
          sessionStorage.removeItem("megjet_checkout_time");
        }
      } catch (error) {
        sessionStorage.removeItem("megjet_checkout_fingerprint");
        sessionStorage.removeItem("megjet_checkout_time");
        throw error;
      } finally {
        submitting = false;
        button.disabled = false;
      }
    };
  }

  const observer = new MutationObserver(() => {
    removeDeliveryBypasses();
    configurePayments();
    protectCheckout();
  });
  observer.observe(document.body, { childList: true, subtree: true });
  removeDeliveryBypasses();
  configurePayments();
  protectCheckout();
})();
