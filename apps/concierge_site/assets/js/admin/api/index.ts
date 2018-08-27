import 'whatwg-fetch';

interface UserResponse {
  id: string;
  email: string;
  phone_number: string;
}

const checkStatus = (res: any) => {
  if (res.status >= 200 && res.status < 300)
    return res;

  throw new Error(res.statusText);
};

const parseJson = (res: any) => res.json();

const translateUserParams = (userResponse: UserResponse) => ({
  id: userResponse.id,
  email: userResponse.email,
  phoneNumber: userResponse.phone_number
});

export const searchForUsers = async (query: string) => {
  try {
    const fetchResults = await fetch(`/api/search/${query}`, {
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    });
    const json = checkStatus(fetchResults);
    const { users } = await parseJson(json);
    return users.map(translateUserParams);
  } catch (error) {
    console.log('Error searching for users', error);
    return [];
  }
};

export const deleteUser = async (id: string) => {
  try {
    const fetchResults = await fetch(`/api/account/${id}`, {
      method: 'DELETE',
      credentials: 'same-origin',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        "x-csrf-token": document.getElementById("admin-app").dataset.token
      }
    });
    const json = checkStatus(fetchResults);
    const res = await parseJson(json);
    return {
      result: res.result,
      id
    };
  } catch (error) {
    console.log('Error deleting user', error);
    throw error;
  }
};
